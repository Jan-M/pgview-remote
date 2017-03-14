<cluster-details>
<div>
    <h2>Host: { this.data.hostname }</h2>
    <h3>Cores: { this.data.cpu_cores }</h3>

    <div id="block-partitions">
        <h3>Partitions</h3>
        <div id="partitions">
            <table class="table table-striped">
            <thead>
                <tr>
                    <th>Device</th>
                    <th>await</th>
                    <th>read</th>
                    <th>write</th>
                    <th>Free</th>
                    <th>Total</th>
                    <th>Path</th>
                    <th>Size</th>
                </tr>
            </thead>
            <tr each={ value, name in this.data.disk_stats }>
                <td>{ name }</div>            
                <td>{ value.device.io.await }</td>
                <td>{ value.device.io.read }</td>
                <td>{ value.device.io.write }</td>                
                <td>{ value.device.space.left }</td>
                <td>{ value.device.space.total }</td>
                <td>{ value.directory.name }</td>
                <td>{ value.directory.size }</td>
            </tr>
            </table>
        </div>
    </div>
    <div id="block-current-processes">
        <h2>Processes</h2>
        <div id="current-processes">
            <table class="table table-striped">
                <thead>
                    <tr>
                        <th>PID</th>
                        <th>Lock</th>
                        <th>Type</th>
                        <th>utime</th>
                        <th>stime</th>
                        <th>read</th>
                        <th>write</th>
                        <th>age</th>
                        <th>DB</th>
                        <th>User</th>
                        <th>Query</th>
                    </tr>
                </thead>
            
                <tr each={ this.data.processes }  class="{ locked_by ? 'danger':'' }">
                    <td>{ pid }</td>
                    <td><virtual each={i in locked_by}>{i} </virtual></td>
                    <td>{ type }</td>
                    <td>{ cpu.user }</td>
                    <td>{ cpu.system }</td>
                    <td>{ io.read }</td>
                    <td>{ io.write }</td>
                    <td>{ username }</td>
                    <td>{ database }</td>
                    <td>{ age }</td>
                    <td class="font-robot">{ query }</td>
                </tr>
            </table>
        </div>
    </div>
</div>
<script type="javascript">

    this.on('route', () => { console.log("route changed")})

    this.tick = () => {
        jQuery.get("/view/default-pod",{}, (data) => { 
                this.update( {data: data} )
            }
        )
    }

    var timer = setInterval(this.tick, 5000)

    this.on('update', (data) => {        
//        console.log(data)
    })

</script>
</cluster-details>