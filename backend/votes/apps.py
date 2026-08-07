from django.apps import AppConfig


class VotesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'votes'

    def ready(self):
        # register sinyal untuk broadcast real-time suara
        from . import signals  # noqa: F401
        try:
            signals.register_signals()
        except Exception as e:  # pragma: no cover
            import logging
            logging.getLogger(__name__).warning(f"register_signals gagal: {e}")