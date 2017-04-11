<member-list>
    <table class="table">
    <thead>
        <tr>
            <th>Pod</th>
            <th>Role</th>
            <th>Phase</th>
            <th>Created</th>
            <th>Node</th>
        </tr>
    </thead>
    <tr each={ member in opts.members }>
        <td><a href="#/clusters/{ parent.opts.cluster }/{ member.name }">{ member.name }</a></td>
        <td><span if={ member.labels["spilo-role"] }>{ member.labels["spilo-role"] }</span></td>
        <td>{ member.status.phase }</td>
        <td>{ (new Date(Date.parse(member.creationTimestamp))).toLocaleDateString('de-DE') } { (new Date(Date.parse(member.creationTimestamp))).toLocaleTimeString('de-DE') }</td>
        <td>{ member.nodeName }</td>
    </tr>
    </table>
    <script type="javascript">
        this.on('update', ()=> {
            console.log(opts.members)
        })
    </script>
</member-list>