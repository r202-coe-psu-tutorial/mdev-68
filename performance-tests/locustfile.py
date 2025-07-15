from locust import HttpUser, task, between
import json
import datetime


class PerformanceTests(HttpUser):
    wait_time = between(1, 3)
    host = "https://ctf.coe.psu.ac.th"

    @task(20)
    def test_index(self):
        res = self.client.get(f"/")
        print("response", datetime.datetime.now(), res)
