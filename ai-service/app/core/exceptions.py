class ProviderFailure(Exception):
    def __init__(self, code: str, status: int = 502, retryable: bool = False, retry_after: float = 0):
        super().__init__(code)
        self.code = code
        self.status = status
        self.retryable = retryable
        self.retry_after = retry_after
