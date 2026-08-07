from rest_framework.permissions import BasePermission, SAFE_METHODS


class HasPermission(BasePermission):
    """Mengharuskan user memiiki `code` permission tertentu (superuser bypass)."""

    code = None

    def has_permission(self, request, view):
        user = request.user
        if not user or not user.is_authenticated:
            return False
        if user.is_superuser:
            return True
        if self.code:
            return user.has_permission(self.code)
        return True


class ManageUsersPermission(HasPermission):
    code = "manage_users"


class ManageTopicsPermission(HasPermission):
    code = "manage_topics"


class ManageCandidatesPermission(HasPermission):
    code = "manage_candidates"


class ManageVotesPermission(HasPermission):
    code = "manage_votes"


class ManageCommentsPermission(HasPermission):
    code = "manage_comments"


class ManageRolesPermission(HasPermission):
    code = "manage_roles"


class ManageElectionsPermission(HasPermission):
    code = "manage_elections"


class IsNetizenVoter(HasPermission):
    """Bisa lihat (SAFE) semua orang; write hanya yang punya `vote`."""

    code = "vote"

    def has_permission(self, request, view):
        user = request.user
        if request.method in SAFE_METHODS:
            if not user or not user.is_authenticated:
                return False
            return True
        if not user or not user.is_authenticated:
            return False
        if user.is_superuser:
            return True
        return user.has_permission("vote")


class CanComment(HasPermission):
    """Baca boleh siapa saja yg login; baca (create) butuh `comment`.
    Untuk delete/update/perubah kamu di level object permission."""

    code = "comment"

    def has_permission(self, request, view):
        user = request.user
        if not user or not user.is_authenticated:
            return False
        if request.method in SAFE_METHODS:
            return True
        if user.is_superuser:
            return True
        return user.has_permission("comment")