<pgview-web>
    <cluster-list clusters={ this.clusters }></cluster-list>    
    <script>
        jQuery.get("/clusters",{}, (data) => { 
                this.update( {clusters: data} )
                console.log(data)
            }
        )
    </script>
</pgview-web>