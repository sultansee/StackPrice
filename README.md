# Stacks (Stacks Price Aggregator)

## Overview

StacksPrice Aggregator is a decentralized price oracle aggregator written in Clarity for the Stacks blockchain. It collects price data from multiple authorized providers, determines a median price, and ensures price validity through various constraints. Additionally, the contract includes a donation system that allows users to create causes, donate, and receive donation certificates.

## Features

### Price Oracle Aggregation
- **Price Collection**: Registered providers can submit price data.
- **Median Calculation**: Prices from multiple providers are aggregated, and a median price is set.
- **Validation**: The contract enforces constraints such as minimum/maximum price limits and acceptable deviations from the median.
- **Historical Price Storage**: Stores price data for verification and analysis.

### Price Provider Management
- **Adding Providers**: The contract owner can register new price providers.
- **Removing Providers**: The contract owner can remove price providers.
- **Provider Status Check**: Verify if a principal is an authorized provider.

### Donation & Fundraising System
- **Cause Creation**: Users can create fundraising causes.
- **Donations**: Users can donate to causes and receive a non-fungible token (NFT) as a donation certificate.
- **Fund Disbursement**: Once the fundraising target is met, the recipient can claim the funds.

## Contract Structure

### Constants
- `PRICE_PRECISION`: Price precision factor (8 decimal places)
- `MAX_PRICE_AGE`: Maximum allowable age of a price update
- `MIN_PRICE_PROVIDERS`: Minimum number of providers required to calculate a valid price
- `MAX_PRICE_PROVIDERS`: Maximum allowed providers
- `MAX_PRICE_DEVIATION`: Maximum deviation allowed from the median price
- `MIN_VALID_PRICE`: Minimum valid price
- `MAX_VALID_PRICE`: Maximum valid price

### Data Variables
- `current-price`: The latest aggregated price
- `last-update-block`: The block number when the last price update occurred
- `active-providers`: The number of currently active price providers

### Error Codes
The contract defines several error messages for validation:
- `ERR_NOT_AUTHORIZED`: Unauthorized action
- `ERR_STALE_PRICE`: The last recorded price is too old
- `ERR_INSUFFICIENT_PROVIDERS`: Not enough price providers to determine a median
- `ERR_PRICE_TOO_LOW`: Submitted price is below the minimum threshold
- `ERR_PRICE_TOO_HIGH`: Submitted price exceeds the maximum threshold
- `ERR_PRICE_DEVIATION`: The price deviates too much from the median
- `ERR_ZERO_PRICE`: The submitted price cannot be zero
- `ERR_INVALID_BLOCK`: Invalid block height
- `ERR_PROVIDER_EXISTS`: Price provider already exists

### Data Structures
- **Price Providers:** Maps provider principals to their authorization status.
- **Provider Prices:** Stores submitted prices per provider.
- **Provider Last Update:** Records the last update time of each provider.
- **Historical Prices:** Stores past prices for verification.
- **Causes:** Tracks fundraising campaigns.
- **Donations:** Stores donation details.
- **Donation Certificates:** Non-fungible tokens (NFTs) awarded for donations.

## Public Functions

### Price Oracle Functions
#### `add-price-provider(provider: principal) -> (ok true | err ERR_NOT_AUTHORIZED)`
Adds a new price provider. Only the contract owner can perform this action.

#### `remove-price-provider(provider: principal) -> (ok true | err ERR_NOT_AUTHORIZED)`
Removes a price provider from the list of authorized providers.

#### `submit-price(price: uint) -> (ok median_price | err ERR_*)`
Submits a price from an authorized provider and updates the aggregated price.

#### `get-current-price() -> (ok price | err ERR_STALE_PRICE)`
Returns the most recent valid price if it is not stale.

#### `get-price-provider-count() -> (ok count)`
Returns the current number of active price providers.

#### `get-provider-status(provider: principal) -> (ok bool)`
Checks if a provider is authorized.

#### `get-last-update-block() -> (ok block_number)`
Returns the last block when the price was updated.

#### `get-historical-price(block: uint) -> (ok price_data | err ERR_INVALID_BLOCK)`
Retrieves the stored price for a specific block.

### Donation & Fundraising Functions
#### `create-cause(name: string, target: uint, recipient: principal) -> (ok cause_id)`
Creates a fundraising cause.

#### `donate(cause-id: uint, amount: uint) -> (ok true | err ERR_*)`
Allows users to donate to a cause and receive a donation certificate.

#### `disburse-funds(cause-id: uint) -> (ok true | err ERR_*)`
Transfers funds to the cause recipient once the target is met.

## Installation & Deployment

1. **Install Clarity Tools**
   Ensure you have Clarity installed for local development and testing.

2. **Deploy the Contract**
   Deploy the contract on Stacks Testnet/Mainnet using Clarinet or the Stacks CLI.

3. **Interact with the Contract**
   Use the Stacks Explorer or a frontend application to call contract functions.

