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
import tokens

from .spiloutils import read_pod, read_pods, read_statefulsets, read_thirdpartyobjects

from pathlib import Path
from flask import Flask, redirect, send_from_directory
from flask_oauthlib.client import OAuth
from .oauth import OAuthRemoteAppWithRefresh
from urllib.parse import urljoin

from .cluster_discovery import DEFAULT_CLUSTERS, StaticClusterDiscoverer, KubeconfigDiscoverer

logger = logging.getLogger(__name__)

SERVER_STATUS = {'shutdown': False}

AUTHORIZE_URL = os.getenv('AUTHORIZE_URL')
TOKENINFO_URL = os.getenv('OAUTH2_TOKEN_INFO_URL')
TEAM_SERVICE_URL = os.getenv('TEAM_SERVICE_URL')

APP_URL = os.getenv('APP_URL')

tokens.configure()
tokens.manage('read-only')
tokens.start()

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


def verify_token(token):
    if not token:
        return False

    r = requests.get(TOKENINFO_URL, headers={'Authorization': token})

    if r.status_code == 200:
        return True

    return False

def authorize_api(f):
    @functools.wraps(f)
    def wrapper(*args, **kwargs):
        if 'Authorization' not in hasattr(flask.request.headers):
            return {}, 401

        if not verify_token(flask.request.headers.get('Authorization')):
            return {}, 401

        return f(*args, **kwargs)

    return wrapper


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


@app.route('/favicon.png')
def favicon():
    return send_from_directory('static/', 'favicon-96x96.png'), 200


@app.route('/css/<path:path>')
@authorize
def send_css(path):
    return send_from_directory('static/', path), 200, {"cache-control": "no-store, no-cache, must-revalidate, post-check=0, pre-check=0, max-age=0",
                                                       "Pragma": "no-cache",
                                                       "Expires": "-1"}


@app.route('/js/<path:path>')
@authorize
def send_js(path):
    return send_from_directory('static/build', path), 200, {"cache-control": "no-store, no-cache, must-revalidate, post-check=0, pre-check=0, max-age=0",
                                                            "Pragma": "no-cache",
                                                            "Expires": "-1"}


def get_teams_for_user(user_name):
    if not TEAM_SERVICE_URL:
        return json.loads(os.getenv("TEAMS", "[]"))

    r = requests.get(TEAM_SERVICE_URL.format(user_name), headers={'Authorization': 'Bearer ' + tokens.get('read-only')})
    teams = r.json()
    teams = list(map(lambda x: x['id_name'], teams)
    )
    return teams


@app.route('/teams')
@authorize
def get_teams():
    teams = get_teams_for_user(flask.session['user_name'])
    return flask.Response(json.dumps(teams), mimetype="application/json"), 200


@app.route('/config')
@authorize
def get_config():
    user_name = flask.session.get("user_name", "NO_USER")
    teams = get_teams_for_user(user_name)
    return flask.Response(json.dumps({"user_name": user_name, "teams": teams}), mimetype="application/json"), 200


@app.route('/')
@authorize
def index():
    return flask.render_template('index.html')


def map_statefulset(cluster):
    return {
        "name": cluster["metadata"]["name"],
        "nodes": cluster["spec"]["replicas"],
        "team": ""
    }


def map_postgresql(cluster):
    return {
        "team": cluster["spec"]["teamId"],
        "name": cluster["metadata"]["name"],
        "nodes": cluster["spec"]["numberOfInstances"]
    }


@app.route('/clusters')
@authorize
def get_list_clusters():

    postgresqls = (list(map(map_postgresql, read_thirdpartyobjects(get_cluster(), "default")["items"])))
    statefulsets = (list(map(map_statefulset, read_statefulsets(get_cluster(), "default")["items"])))

    postgresql_names = list(map(lambda x: x["name"], postgresqls))

    clusters = json.dumps(postgresqls + list(filter(lambda x: x["name"] not in postgresql_names, statefulsets)))

    return flask.Response(clusters, mimetype='application/json')


def map_member(member):
    return {
        "name": member["metadata"]["name"],
        "labels": {"spilo-role": member["metadata"]["labels"].get("spilo-role", "")},
        "creationTimestamp": member["metadata"]["creationTimestamp"],
        "status": member["status"],
        "nodeName": member["spec"]["nodeName"]
    }


@app.route('/clusters/<cluster>')
@authorize
def get_list_members(cluster: str):
    pods = read_pods(get_cluster(), "default", cluster)
    pods = list(map(map_member, pods["items"]))
    return flask.Response(json.dumps(pods), mimetype="application/json"), 200


MOCK_BGMON_IP = os.getenv('MOCK_BGMON_IP', None)


@app.route('/clusters/<cluster>/pod/<pod>')
@authorize
def get_pod_data(cluster: str, pod: str):
    logger.info("Getting pod data for: {}".format(pod))
    pod_data = read_pod(get_cluster(), "default", pod)

    if not MOCK_BGMON_IP:
        podIP = pod_data.get("status", {}).get("podIP", None)
    else:
        podIP = MOCK_BGMON_IP

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

    r = requests.get(TOKENINFO_URL, headers={'Authorization': 'Bearer ' + flask.session['auth_token'][0]})
    flask.session['user_name'] = r.json().get('uid')

    logger.info("Login from: {}".format(flask.session['user_name']))

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
