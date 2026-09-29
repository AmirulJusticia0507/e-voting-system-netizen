from django.core.exceptions import ValidationError
from django.test import TestCase

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
