from django.test import TestCase
from django.test import SimpleTestCase

class ApiTests(SimpleTestCase):
    
    def test_sessionsGetHttpStatus_200(self):
        foo = "bar"
        # TODO: learn how to mock a DB
        # response = self.client.get('/sessions')
        # self.assertEqual(response.status_code, 200)