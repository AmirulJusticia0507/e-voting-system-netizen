from django.db import models
from users.models import User
from topics.models import Topic
from candidates.models import Candidate

class Vote(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    topic = models.ForeignKey(Topic, on_delete=models.CASCADE)
    candidate = models.ForeignKey(Candidate, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "topic")  # 1 user = 1 vote per topic

    def __str__(self):
        return f"{self.user.phone_number} → {self.candidate.name}"
