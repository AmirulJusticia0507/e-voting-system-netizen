from django.db import models
from topics.models import Topic

class Candidate(models.Model):
    topic = models.ForeignKey(Topic, on_delete=models.CASCADE, related_name="candidates")
    name = models.CharField(max_length=200)
    photo = models.ImageField(upload_to="candidates/photos/")
    bio = models.TextField(blank=True)

    def __str__(self):
        return f"{self.name} ({self.topic.title})"

    # 🔹 Helper properties untuk total like/dislike dari komentar
    @property
    def total_likes(self):
        return self.comment_set.aggregate(total=models.Sum("likes"))["total"] or 0

    @property
    def total_dislikes(self):
        return self.comment_set.aggregate(total=models.Sum("dislikes"))["total"] or 0