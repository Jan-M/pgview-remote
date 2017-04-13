<cluster-details>
<div if={ this.data }>
    <div id="block-cpu" style="float:left; width: 50%">
        <h3>CPU</h3>
        <div id="cpu">
            <table class="table">
                <thead>
                    <tr>
                        <th>Idle %</th>
                        <th>System %</th>
                        <th>User %</th>
                        <th>IOWait</th>
                        <th>Load 1</th>
                        <th>Load 5</th>
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
    <div id="cpucharts" style="float:right; width:50%; height:150px;">

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
                        <th>Commit Limit</th>
                        <th>Commited As</th>
                        <th>Dirty</th>
                    </tr>
                </thead>
                <tr>
                    <td>{ this.mFormat(this.data.system_stats.memory.total) }B</td>
                    <td>{ this.mFormat(this.data.system_stats.memory.free) }B</td>
                    <td>{ this.mFormat(this.data.system_stats.memory.buffers) }B</td>
                    <td>{ this.mFormat(this.data.system_stats.memory.cached) }B</td>
                    <td>{ this.mFormat(this.data.system_stats.memory.commit_limit) }B</td>
                    <td>{ this.mFormat(this.data.system_stats.memory.committed_as) }B</td>
                    <td>{ this.mFormat(this.data.system_stats.memory.dirty) }B</td>
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
                <td>{ this.mFormat(value.device.space.left) }B</td>
                <td>{ this.mFormat(value.device.space.total) }B</td>
                <td>{ value.directory.name }</td>
                <td>{ this.mFormat(value.directory.size) }B</td>
            </tr>
            </table>
        </div>
    </div>
    <div id="block-current-processes">
        <h2>Processes { this.data.postgresql.connections.active } / { this.data.postgresql.connections.total } of maximum { this.data.postgresql.connections.max }</h2>
        <div id="current-processes">
            <table class="table table-striped process-table">
                <thead>
                    <tr>
                        <th style="width:65px;">PID</th>
                        <th style="width:65px;">Lock</th>
                        <th style="width:200px;">Type</th>
                        <th style="width:60px;">utime</th>
                        <th style="width:60px;">stime</th>
                        <th style="width:60px;">read</th>
                        <th style="width:60px;">write</th>
                        <th style="width:60px;">age</th>
                        <th style="width:180px;">DB</th>
                        <th style="width:180px;">User</th>
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
<style>
  .process-table { font-size: 12px }
</style>
<script type="javascript">

    this.mFormat = d3.format('.4s')

    this.cpuLoad = []

    this.tick = () => {

        jQuery.get("/clusters/" + this.opts.cluster + "/pod/" + this.opts.pod,{}, (data) => { 
                this.update( {data: data} )
            }
        )
    }

    this.poll_timer = setInterval(this.tick, 5000)
    this.tick()

    this.on('update', (data) => {
        this.cpuLoad.push([(new Date()).getTime(), this.data.system_stats.load_average[0]])
        this.cpuLoad.slice(60)
        $.plot("#cpucharts", [ this.cpuLoad ], { grid: { borderWidth: 0 }, xaxis: {mode: "time"}, yaxis: { min: 0 } });        
    })

    this.on('unmount', () => {
        clearInterval(this.poll_timer)
    })

</script>
</cluster-details>