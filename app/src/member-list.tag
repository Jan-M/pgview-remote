<member-list>
    <div each={ member in opts.members }>
        <div>
            <a href="#/clusters/{ parent.opts.cluster }/{ member.name }">{ member.name }</a>
            <span if={ member.labels["spilo-role"] }>{ member.labels["spilo-role"] }</span>
        </div>
    </div>
    <script>
    console.log("members", opts.cluster, opts.members)
    </script>
</member-list>