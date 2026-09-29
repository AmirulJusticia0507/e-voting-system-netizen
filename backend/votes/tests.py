from django.test import TestCase
from rest_framework.test import APIClient

from candidates.models import Candidate
from topics.models import Topic


class CivicAggregateTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.topic = Topic.objects.create(
            title="Kebijakan transportasi",
            topic_type=Topic.TopicType.CIVIC_POLL,
            publication_status=Topic.PublicationStatus.PUBLISHED,
        )
        Candidate.objects.create(topic=self.topic, code="A", name="Setuju")
        Candidate.objects.create(topic=self.topic, code="B", name="Tidak setuju")

    def test_public_aggregate_contains_only_counts(self):
        response = self.client.get(f"/api/votes/public/civic/{self.topic.id}/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["total_responses"], 0)
        self.assertEqual(len(response.data["options"]), 2)
        self.assertNotIn("users", response.data)
        self.assertNotIn("votes", response.data)

    def test_draft_is_not_public(self):
        self.topic.publication_status = Topic.PublicationStatus.DRAFT
        self.topic.save(update_fields=["publication_status"])

        response = self.client.get(f"/api/votes/public/civic/{self.topic.id}/")

        self.assertEqual(response.status_code, 404)
