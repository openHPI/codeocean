from exercise import *
import unittest

class ExerciseTests(unittest.TestCase):
    def test_even(self):
        for x in [1, 3, 5, 7, 9]:
            self.assertFalse(even(x))
        for x in [2, 4, 6, 8, 10]:
            self.assertTrue(even(x))

    def test_odd(self):
        for x in [1, 3, 5, 7, 9]:
            self.assertTrue(odd(x))
        for x in [2, 4, 6, 8, 10]:
            self.assertFalse(odd(x))
