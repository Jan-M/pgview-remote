<cluster-details>
<div>
    <h2>Host: { this.data.hostname }</h2>
    <h3>Cores: { this.data.cpu_cores }</h3>
    
    <h2>Current processes</h2>
    <div id="current_processes">
        <ol>
            <li each={ this.data.processes }>
                <div>{ pid }</div>
                <div>{ type }</div>
                <div>{ username }</div>
                <div>{ query}</div>
            </li>
        </ol>
    </div>
</div>
<script type="javascript">

    this.tick = () => {
        jQuery.get("/view/default-pod",{}, (data)=>{ this.update({data: data})})
    }

    var timer = setInterval(this.tick, 2000)

    this.on('update', (data) => {
        console.log(data)
    })

</script>
</cluster-details>