import time
import json
import request


class MockCluster:

    def get_pods(self):
        return [{"name":"cluster-1-XFF", "role":"master", "ip": "localhost", "port": "8080"},
                {"name":"cluster-1-XFE", "role":"slave", "ip": "localhost", "port": "8080"},
                {"name":"cluster-1-XFS", "role":"slave", "ip": "localhost", "port": "8080"},
                {"name":"cluster-2-SJE", "role":"master", "ip": "localhost", "port": "8080"}]
