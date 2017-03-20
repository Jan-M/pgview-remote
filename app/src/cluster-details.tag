<cluster-details>
<div if={ this.data }>
    <div id="block-cpu">
        <h3>Memory</h3>
        <div id="cpu">
            <table class="table">
                <thead>
                    <tr>
                        <th>Idle %</th>
                        <th>System %</th>
                        <th>User %</th>
                        <th>IOWait</th>
                        <td>Load 1</th>
                        <td>Load 5</th>
                        <th>Load 15</th>
                    </tr>
                </thead>
                <tr>
                    <td>{ this.data.system_stats.cpu.idle }</td>
                    <td>{ this.data.system_stats.cpu.system }</td>
                    <td>{ this.data.system_stats.cpu.user }</td>
                    <td>{ this.data.system_stats.iowait }</td>
                    <td>{ this.data.system_stats.load_average[0] }</td>
                    <td>{ this.data.system_stats.load_average[1] }</td>
                    <td>{ this.data.system_stats.load_average[2] }</td>
                </tr>
            </table>
        </div>
    </div>
    <div id="block-memory">
        <h3>Memory</h3>
        <div id="memory">
            <table class="table">
                <thead>
                    <tr>
                        <th>Total</th>
                        <th>Free</th>
                        <th>Buffers</th>
                        <th>Cached</th>
                        <td>Commit Limit</th>
                        <td>Commitd As</th>
                        <th>Dirty</th>
                    </tr>
                </thead>
                <tr>
                    <td>{ this.data.system_stats.memory.total }</td>
                    <td>{ this.data.system_stats.memory.free }</td>
                    <td>{ this.data.system_stats.memory.buffers }</td>
                    <td>{ this.data.system_stats.memory.cached }</td>
                    <td>{ this.data.system_stats.memory.commit_limit }</td>
                    <td>{ this.data.system_stats.memory.commited_as }</td>
                    <td>{ this.data.system_stats.memory.dirty }</td>
                </tr>
            </table>
        </div>
    </div>
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
                    <td>{ age }</td>
                    <td>{ database }</td>
                    <td>{ username }</td>
                    <td class="font-robot">{ query }</td>
                </tr>
            </table>
        </div>
    </div>
</div>
<script type="javascript">

    this.tick = () => {

        jQuery.get("/clusters/" + this.opts.cluster + "/pod/" + this.opts.pod,{}, (data) => { 
                this.update( {data: data} )
            }
        )
    }

    this.poll_timer = setInterval(this.tick, 5000)
    this.tick()

    this.on('update', (data) => {

    })

    this.on('unmount', () => {
        clearInterval(this.poll_timer)
    })

</script>
</cluster-details>