<cluster-list>
  <nav class="navbar navbar-inverse navbar-fixed-top">
    <div class="container">
        <div class="navbar-header">
            <a class="navbar-brand">PGView Remote</a>
        </div>
        <div id="navbar" class="navbar-collapse collapse">
            <ul class="nav navbar-nav">
                <li class="active"><a href="#/clusters" onclick={  }>Home</a></li>
                <li if={ this.cluster }><a href="#/clusters/{ this.cluster }"><b>Cluster</b> { this.cluster }</a></li>
                <li if={ this.cluster && this.pod }><a href="#/clusters/{ this.cluster }/{ this.pod }"><b>Pod</b> { this.pod }</a></li>
            </ul>
        </div>
    </div>
  </nav>

  <virtual if={ !this.cluster }>
  <div>
    <h1>My Team's clusters</h1>
  </div>
  <table class="table">
    <thead>
      <tr>
        <th style="width:15%">Team</th>
        <th style="width:15%">Instances</th>
        <th style="width:80%">Name</th>
      </tr>
    </thead>
    <tr each={ this.myClusters }>
      <td>{ team }</td>
      <td>{ nodes }</td>
      <td><a href="#/clusters/{name}">{name}</a></td>
    </tr>
    </table>

    <div>
    <h1>All clusters</h1>
  </div>
  <table class="table">
    <thead>
      <tr>
        <th style="width:15%">Team</th>
        <th style="width:15%">Instances</th>
        <th style="width:80%">Name</th>
      </tr>
    </thead>
    <tr each={ this.otherClusters }>
      <td>{ team }</td>
      <td>{ nodes }</td>
      <td><a href="#/clusters/{name}">{name}</a></td>
    </tr>
    </table>
  </virtual>

  <div if={ this.cluster && !this.pod }>
    <h1>Pod Selection</h1>
    <member-list cluster={ this.cluster } members={ this.members }></member-list>
  </div>

  <virtual if={ this.cluster && this.pod }>
    <cluster-details cluster={ this.cluster } pod={ this.pod }></cluster-details>
  </virtual>

  <script>

  updateMembers = () => {
      jQuery.get("/clusters/" + this.cluster,{}, (data) => {
              this.update({members: data})
          }
      )
  }

  route('/clusters', () => {
    this.cluster = null;
    this.pod = null;

    this.update()
  })

  this.teams = []
  this.user_name = ""

  jQuery.get('/config',(data) => {
    this.update({teams: data.teams.map((x) => { return x.toLowerCase() }), user_name: data.user_name})
  })

  this.on('update', () => {
    console.log("update")
    if(this.opts.clusters && this.teams ) {
      this.myClusters = this.opts.clusters.filter((x) => {        
        return this.teams.includes(x.team.toLowerCase())
      })
      this.otherClusters = this.opts.clusters.filter((x) => {        
        return ! this.teams.includes(x.team.toLowerCase())
      })
    }
    else {
      this.otherClusters = this.opts.clusters
      this.myClusters = []
    }
  })

  route('/clusters/*', (id) => { 
    this.cluster = id
    this.pod = null
    updateMembers()
  } )

  route('/clusters/*/*', (cluster, pod) => {
    this.cluster = cluster
    this.pod = pod

    this.update()
  })

  route.start(true)

  </script>
</cluster-list>
