#!/usr/bin/env python3

import gevent.monkey

gevent.monkey.patch_all()

import click
import flask
import functools
import gevent
import gevent.wsgi
import json
import logging
import os
import signal
import time
import requests

from .spiloutils import read_pod, read_pods, read_statefulsets

from pathlib import Path
from flask import Flask, redirect, send_from_directory
from flask_oauthlib.client import OAuth
from .oauth import OAuthRemoteAppWithRefresh
from urllib.parse import urljoin

from .cluster_discovery import DEFAULT_CLUSTERS, StaticClusterDiscoverer, KubeconfigDiscoverer

logger = logging.getLogger(__name__)

SERVER_STATUS = {'shutdown': False}
AUTHORIZE_URL = os.getenv('AUTHORIZE_URL')
APP_URL = os.getenv('APP_URL')

app = Flask(__name__)

oauth = OAuth(app)

auth = OAuthRemoteAppWithRefresh(
    oauth,
    'auth',
    request_token_url=None,
    access_token_method='POST',
    access_token_url=os.getenv('ACCESS_TOKEN_URL'),
    authorize_url=AUTHORIZE_URL
)
oauth.remote_apps['auth'] = auth


def authorize(f):
    @functools.wraps(f)
    def wrapper(*args, **kwargs):
        if AUTHORIZE_URL and 'auth_token' not in flask.session:
            return redirect(urljoin(APP_URL, '/login'))
        return f(*args, **kwargs)

    return wrapper


@app.route('/health')
def health():
    if SERVER_STATUS['shutdown']:
        flask.abort(503)
    else:
        return 'OK'

@app.route('/css/<path:path>')
@authorize
def send_css(path):
    return send_from_directory('static/', path), 200, {"cache-control":"no-store, no-cache, must-revalidate, post-check=0, pre-check=0, max-age=0",
                                                       "Pragma":"no-cache",
                                                       "Expires":"-1"}

@app.route('/js/<path:path>')
@authorize
def send_js(path):
    return send_from_directory('static/build', path), 200, {"cache-control":"no-store, no-cache, must-revalidate, post-check=0, pre-check=0, max-age=0",
                                                            "Pragma":"no-cache",
                                                            "Expires":"-1"}

@app.route('/')
@authorize
def index():
    return flask.render_template('index.html')


@app.route('/clusters')
@authorize
def get_list_clusters():
    stateful_sets = read_statefulsets(get_cluster(), "default")
    logger.info(stateful_sets)
    clusters = (list(map(lambda x: x["metadata"], stateful_sets["items"])))
    clusters = json.dumps(clusters)
    return flask.Response(clusters, mimetype='application/json')


@app.route('/clusters/<cluster>')
@authorize
def get_list_members(cluster: str):
    pods = read_pods(get_cluster(), "default", cluster)
    logger.info(pods)
    pods = list(map(lambda x: x["metadata"], pods["items"]))
    return flask.Response(json.dumps(pods), mimetype="application/json")


@app.route('/clusters/<cluster>/pod/<pod>')
@authorize
def get_pod_data(cluster: str, pod: str):
    logger.info("Getting pod data for: {}".format(pod))
    pod_data = read_pod(get_cluster(), "default", pod)
    logger.info(pod_data)

    podIP = pod_data.get("status",{}).get("podIP", None)

    if not podIP:
        return "", 500

    port = 8080
    r = requests.get("http://{}:{}/".format(podIP, port))
    return flask.Response(r.text, mimetype='application/json')


@app.route('/login')
def login():
    redirect_uri = urljoin(APP_URL, '/login/authorized')
    return auth.authorize(callback=redirect_uri)


@app.route('/logout')
def logout():
    flask.session.pop('auth_token', None)
    return redirect(urljoin(APP_URL, '/'))


@app.route('/login/authorized')
def authorized():
    resp = auth.authorized_response()
    if resp is None:
        return 'Access denied: reason=%s error=%s' % (
            flask.request.args['error'],
            flask.request.args['error_description']
        )
    if not isinstance(resp, dict):
        return 'Invalid auth response'
    flask.session['auth_token'] = (resp['access_token'], '')
    return redirect(urljoin(APP_URL, '/'))


def shutdown():
    # just wait some time to give Kubernetes time to update endpoints
    # this requires changing the readinessProbe's
    # PeriodSeconds and FailureThreshold appropriately
    # see https://godoc.org/k8s.io/kubernetes/pkg/api/v1#Probe
    gevent.sleep(10)
    exit(0)


def exit_gracefully(signum, frame):
    logger.info('Received TERM signal, shutting down..')
    SERVER_STATUS['shutdown'] = True
    gevent.spawn(shutdown)


def print_version(ctx, param, value):
    if not value or ctx.resilient_parsing:
        return
    click.echo('PGView Web {}'.format(pgview_web.__version__))
    ctx.exit()


class CommaSeparatedValues(click.ParamType):
    name = 'comma_separated_values'

    def convert(self, value, param, ctx):
        if isinstance(value, str):
            values = filter(None, value.split(','))
        else:
            values = value
        return values

CLUSTER = None
def get_cluster():
    return CLUSTER

def set_cluster(c):
    global CLUSTER
    CLUSTER = c
    return CLUSTER


@click.command(context_settings={'help_option_names': ['-h', '--help']})
@click.option('-V', '--version', is_flag=True, callback=print_version, expose_value=False, is_eager=True,
              help='Print the current version number and exit.')
@click.option('-p', '--port', type=int, help='HTTP port to listen on (default: 8081)', envvar='SERVER_PORT', default=8081)
@click.option('-m', '--mock', is_flag=True, help='Mock Kubernetes Clusters', envvar='MOCK')
@click.option('-d', '--debug', is_flag=True, help='Verbose logging')
@click.option('--secret-key', help='Secret key for session cookies', envvar='SECRET_KEY', default='development')
@click.option('--clusters', type=CommaSeparatedValues(),
              help='Comma separated list of Kubernetes API server URLs (default: {})'.format(DEFAULT_CLUSTERS), envvar='CLUSTERS')
@click.option('--kubeconfig-path', type=click.Path(exists=True), help='Path to kubeconfig file', envvar='KUBECONFIG_PATH')
@click.option('--kubeconfig-contexts', type=CommaSeparatedValues(),
              help='List of kubeconfig contexts to use (default: use all defined contexts)', envvar='KUBECONFIG_CONTEXTS')
def main(port, mock, secret_key, debug, clusters: list, kubeconfig_path, kubeconfig_contexts: list):
    logging.basicConfig(level=logging.DEBUG if debug else logging.INFO)

    discoverer = StaticClusterDiscoverer([])
    logger.info(discoverer.get_clusters()[0])

    set_cluster(discoverer.get_clusters()[0])

    app.debug = debug
    app.secret_key = secret_key

    signal.signal(signal.SIGTERM, exit_gracefully)
    http_server = gevent.wsgi.WSGIServer(('0.0.0.0', port), app)
    logger.info('Listening on :{}..'.format(port))
    http_server.serve_forever()
