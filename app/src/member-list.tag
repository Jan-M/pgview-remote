<member-list>
    <div each={ member in opts.members }>
        <div>
            <a href="#/clusters/{ parent.opts.cluster }/{ member }">{ member }</a>    
        </div>
    </div>
    <script>
    console.log("members", opts.cluster)
    </script>
</member-list>