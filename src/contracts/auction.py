from src.util import NEUTRON_NETWORK_CONFIG
from cosmpy.aerial.contract import LedgerContract
from cosmpy.aerial.client import LedgerClient
from typing import Any


class AuctionProvider:
    """
    Provides pricing and asset information for an arbitrary auction on valenece.
    """

    def __init__(self, contract: LedgerContract, asset_a: str, asset_b: str):
        self.contract = contract
        self.asset_a_denom = asset_a
        self.asset_b_denom = asset_b

    def simulate_swap_asset_a(self, amount: int) -> float:
        auction_info = self.contract.query("get_auction")

        print(self.contract.address)

        # No swap is possible since the auction is closed
        if auction_info["status"] != "started":
            return 0

        return float(self.contract.query("get_price")["price"])

    def asset_a(self) -> str:
        return self.asset_a_denom

    def asset_b(self) -> str:
        return self.asset_b_denom


class AuctionDirectory:
    """
    A wrapper around an auction manager providing:
    - Accessors for all auctions on valence
    - AuctionProviders for each auction
    """

    def __init__(self, deployments: dict[str, Any]):
        self.client = LedgerClient(NEUTRON_NETWORK_CONFIG)
        self.deployment_info = deployments["auctions"]["neutron"]

        deployment_info = self.deployment_info["auctions_manager"]
        self.directory_contract = LedgerContract(
            deployment_info["src"], self.client, address=deployment_info["address"]
        )

    def auctions(self) -> dict[str, dict[str, AuctionProvider]]:
        """ "
        Gets an AuctionProvider for every pair on valence.
        """

        auction_infos = self.directory_contract.query(
            {"get_pairs": {"start_after": None, "limit": None}}
        )
        auctions: dict[str, dict[str, AuctionProvider]] = {}

        for auction in auction_infos:
            pair, addr = auction
            asset_a, asset_b = pair

            provider = AuctionProvider(
                LedgerContract(
                    self.deployment_info["auction"]["src"], self.client, address=addr
                ),
                asset_a,
                asset_b,
            )

            if asset_a not in auctions:
                auctions[asset_a] = {}

            auctions[asset_a][asset_b] = provider

        return auctions
