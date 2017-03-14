import riot from 'riot'
import route from 'riot-route'
import 'riot-hot-reload'
import './cluster-list.tag'
import './cluster-details.tag'
import './pgview-web.tag'

/* eslint-disable no-console */
route('/view', () => { console.log('view')})

/* eslint-disable no-console */
route('/cluster/*/*', (a,b) => { console.log('cluster', a, b)})

route.start()

riot.mount('pgview-web', {})
