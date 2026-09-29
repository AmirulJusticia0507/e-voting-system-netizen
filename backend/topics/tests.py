from django.core.exceptions import ValidationError
from django.test import TestCase
from rest_framework.test import APIClient

from users.models import User

from .models import CivicPollSource, Topic


class CivicPollSourceTests(TestCase):
    def test_source_requires_civic_poll_topic(self):
        topic = Topic.objects.create(title="Pemilu")
        source = CivicPollSource(
            topic=topic,
            source_type=CivicPollSource.SourceType.VIDEO,
            title="Rapat publik",
        )

        with self.assertRaises(ValidationError):
            source.full_clean()

    def test_segment_end_cannot_precede_start(self):
        topic = Topic.objects.create(
            title="Transportasi publik",
            topic_type=Topic.TopicType.CIVIC_POLL,
        )
        source = CivicPollSource(
            topic=topic,
            source_type=CivicPollSource.SourceType.VIDEO,
            title="Rapat publik",
            segment_start_seconds=120,
            segment_end_seconds=60,
        )

        with self.assertRaises(ValidationError):
            source.full_clean()


class CivicPollImportTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        admin = User.objects.create_superuser(
            phone_number="081234567890",
            username="admin",
            password="secret",
        )
        self.client.force_authenticate(admin)

    def test_import_creates_unpublished_poll_with_source_and_options(self):
        response = self.client.post(
            "/api/topics/import-civic-draft/",
            {
                "schema_version": "1.0",
                "event_id": "civic-001",
                "generated_at": "2026-09-29T10:00:00+07:00",
                "source": {
                    "type": "youtube_video",
                    "url": "https://example.com/rapat",
                    "publisher": "DPRD Contoh",
                    "title": "Rapat kebijakan",
                    "segment_start_seconds": 10,
                    "segment_end_seconds": 60,
                },
                "legal_audit": {"summary": "Ringkasan yang telah diaudit."},
                "poll_draft": {
                    "question": "Apakah kebijakan ini perlu dilanjutkan?",
                    "options": [
                        {"code": "A", "label": "Setuju"},
                        {"code": "B", "label": "Tidak setuju"},
                    ],
                    "opens_at": "2026-09-29T12:00:00+07:00",
                    "closes_at": "2026-10-06T12:00:00+07:00",
                },
                "review": {"status": "DRAFT"},
            },
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        topic = Topic.objects.get()
        self.assertEqual(topic.topic_type, Topic.TopicType.CIVIC_POLL)
        self.assertEqual(topic.publication_status, Topic.PublicationStatus.DRAFT)
        self.assertFalse(topic.is_active)
        self.assertEqual(topic.candidates.count(), 2)
        self.assertEqual(topic.civic_source.publisher, "DPRD Contoh")
