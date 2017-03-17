<member-list>
    <div each={ member in opts.members }>
        <div>
            <a href="#/clusters/{ parent.opts.cluster }/{ member.name }">{ member.name }</a>    
        </div>
    </div>
    <script>
    console.log("members", opts.cluster, opts.members)
    </script>
</member-list>