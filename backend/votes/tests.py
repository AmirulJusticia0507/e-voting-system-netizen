from django.test import TestCase
from rest_framework.test import APIClient

from candidates.models import Candidate
from topics.models import Topic


class CivicAggregateTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.topic = Topic.objects.create(
            title="Kebijakan transportasi",
            external_event_id="civic-transport-001",
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
        self.assertEqual(response.data["external_event_id"], "civic-transport-001")
        self.assertIn("evidence_root", response.data)
        self.assertFalse(response.data["voided"])
        self.assertNotIn("users", response.data)
        self.assertNotIn("votes", response.data)

    def test_draft_is_not_public(self):
        self.topic.publication_status = Topic.PublicationStatus.DRAFT
        self.topic.save(update_fields=["publication_status"])

        response = self.client.get(f"/api/votes/public/civic/{self.topic.id}/")

        self.assertEqual(response.status_code, 404)

    def test_aggregate_exposes_correction_metadata(self):
        successor = Topic.objects.create(
            title="Pertanyaan koreksi",
            external_event_id="civic-transport-002",
            topic_type=Topic.TopicType.CIVIC_POLL,
        )
        self.topic.is_voided = True
        self.topic.correction_reason = "Pertanyaan diperbaiki."
        self.topic.superseded_by = successor
        self.topic.save(
            update_fields=["is_voided", "correction_reason", "superseded_by"]
        )

        response = self.client.get(f"/api/votes/public/civic/{self.topic.id}/")

        self.assertTrue(response.data["voided"])
        self.assertEqual(response.data["correction_reason"], "Pertanyaan diperbaiki.")
        self.assertEqual(response.data["superseded_by_event_id"], "civic-transport-002")
