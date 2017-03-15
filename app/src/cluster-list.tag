<cluster-list>  
  <virtual if={ !this.cluster }>
  <div>
    <h1>Cluster Selection</h1>
  </div>
  <div each={ opts.clusters }>
    <a href="#/clusters/{id}">{id}: {name}</a>
  </div>
  </virtual>

  <div if={ this.cluster && !this.pod }>
    <h1><a href="#/clusters">Home</a> - Cluster { this.cluster }</h1>
    <member-list cluster={ this.cluster } members={ this.members }></member-list>
  </div>

  <virtual if={ this.cluster && this.pod }>
    <h1><a href="#/clusters">Home</a> - <a href="#/clusters/{ this.cluster }">Cluster { this.cluster}</a> - Pod { this.pod }</h1>
    <cluster-details cluster={ this.cluster } pod={ this.pod }></cluster-details>
  </virtual>

  <script>

  updateMembers = () => {
      jQuery.get("/clusters/"+this.cluster,{}, (data) => {
              this.update( {members: data[this.cluster]} )
          }
      )
  }

  route('/clusters', () => {
    this.cluster = null;
    this.pod = null;

    this.update()
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