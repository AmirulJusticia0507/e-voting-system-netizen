from rest_framework import serializers
from .models import Topic
from election.models import ElectionPeriod, Region


class TopicSerializer(serializers.ModelSerializer):
    election_name = serializers.SerializerMethodField()
    region_name = serializers.SerializerMethodField()

    class Meta:
        model = Topic
        fields = "__all__"
        read_only_fields = ["election_name", "region_name"]

    def get_election_name(self, obj):
        return obj.election.name if obj.election else None

    def get_region_name(self, obj):
        return obj.region.name if obj.region else None