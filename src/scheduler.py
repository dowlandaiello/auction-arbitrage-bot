from src.contracts.auction import AuctionDirectory, AuctionProvider
from src.contracts.pool.provider import PoolProvider
from src.contracts.pool.astroport import AstroportPoolDirectory
from src.contracts.pool.osmosis import OsmosisPoolDirectory
from src.util import deployments
from typing import Callable, List


class Scheduler:
    """
    A registry of pricing providers for different assets,
    which can be polled alongside a strategy function which
    may interact with registered providers.
    """

    def __init__(
        self,
        strategy: Callable[
            [
                dict[str, dict[str, List[PoolProvider]]],
                dict[str, dict[str, AuctionProvider]],
            ],
            None,
        ],
    ):
        self.strategy = strategy
        self.providers: dict[str, dict[str, List[PoolProvider]]] = {}

        auction_manager = AuctionDirectory(deployments())
        self.auctions = auction_manager.auctions()

    def register_provider(self, provider: PoolProvider):
        """
        Registers a pool provider, enqueing it to future strategy function polls.
        """

        if provider.asset_a() not in self.providers:
            self.providers[provider.asset_a()] = {}

        if provider.asset_b() not in self.providers:
            self.providers[provider.asset_b()] = {}

        if provider.asset_b() not in self.providers[provider.asset_a()]:
            self.providers[provider.asset_a()][provider.asset_b()] = []

        if provider.asset_a() not in self.providers[provider.asset_b()]:
            self.providers[provider.asset_b()][provider.asset_a()] = []

        self.providers[provider.asset_a()][provider.asset_b()].append(provider)
        self.providers[provider.asset_b()][provider.asset_a()].append(provider)

    def poll(self):
        """
        Polls the strategy functionw with all registered providers.
        """

        self.strategy(self.providers, self.auctions)
