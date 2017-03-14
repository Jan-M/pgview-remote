<cluster-list>
  <div>
    <h1>Cluster Members</h1>
  </div>
  <div id="members-list">
  <div each={ members } onclick={ goto }>
    <div>
      <div>{ host }</div>
      <div class="list-role">Role: { role }</div>
      <div class="list-load">Load1: { load1 }</div>
    </div>
  </div>
  </div>
  <script>

  route('/clusters/*', () => {console.log('cluster navigation')})

  route.start()

  this.goto = () => {
    console.log("trigger goto")
    route('/clusters/a')
  }

  this.members = [{host: "host1", role: "master", load1: 15 },
                  {host: "host2", role: "slave", load1: 3 },
                  {host: "host3", role: "slave", load1: 2 }]

  </script>
</cluster-list>