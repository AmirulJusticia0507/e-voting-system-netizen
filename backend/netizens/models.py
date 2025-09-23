from django.db import models
from users.models import User

# Tidak perlu model baru, cukup pakai User dengan flag is_netizen
User.add_to_class('is_netizen', models.BooleanField(default=True))
