// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol';
import './libraries/TickMath.sol';
import './libraries/FullMath.sol';
import './interface/IEarthaTokenRate.sol';

contract EarthaTokenRateV2 is AccessControl, IEarthaTokenRate {
    bytes32 public constant SOURCE_SETTER_ROLE = keccak256('SOURCE_SETTER_ROLE');
    string public constant BaseCurrency = 'BNB';

    mapping(string => AggregatorV3Interface) public rateFeeds;

    AggregatorV3Interface public USDPriceFeed;
    address public immutable BaseAddress;
    address public immutable EARAddress;
    IUniswapV2Factory public immutable uniswapFactory;
    uint256 public immutable decimals;

    constructor(
        uint256 decimals_,
        AggregatorV3Interface USDFeed,
        AggregatorV3Interface JPYFeed,
        AggregatorV3Interface EURFeed,
        AggregatorV3Interface GBPFeed,
        AggregatorV3Interface BTCFeed,
        address BaseAddress_,
        address EARAddress_,
        IUniswapV2Factory uniswapFactoryAddress_
    ) AccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(SOURCE_SETTER_ROLE, _msgSender());

        decimals = decimals_;
        BaseAddress = BaseAddress_;
        EARAddress = EARAddress_;
        uniswapFactory = uniswapFactoryAddress_;
        USDPriceFeed = USDFeed;
        rateFeeds['JPY'] = JPYFeed;
        rateFeeds['EUR'] = EURFeed;
        rateFeeds['GBP'] = GBPFeed;
        rateFeeds['BTC'] = BTCFeed;
    }

    modifier sourceSetterOnly() {
        require(hasRole(SOURCE_SETTER_ROLE, _msgSender()), 'EarthaTokenRate: must have source setter role to set role');
        _;
    }

    function setSource(string calldata currencyCode, AggregatorV3Interface source)
        external
        virtual
        override
        sourceSetterOnly()
        returns (bool)
    {
        rateFeeds[currencyCode] = source;
        emit UpdatedSource(currencyCode, source);
        return true;
    }

    function setUSDSource(AggregatorV3Interface source) external virtual override sourceSetterOnly() returns (bool) {
        USDPriceFeed = source;
        emit UpdatedSource('USD', source);
        return true;
    }

    function getXTo(uint256 amount, string calldata currencyCode) public view virtual override returns (uint256) {
        if (_compareStrings(currencyCode, 'EAR')) {
            return amount;
        } else if (_compareStrings(currencyCode, BaseCurrency)) {
            return _getBaseTo(amount);
        } else if (_compareStrings(currencyCode, 'USD')) {
            return _getUSDTo(amount);
        } else {
            return _getOtherTo(amount, currencyCode);
        }
    }

    function getToX(uint256 amount, string calldata currencyCode) public view virtual override returns (uint256) {
        if (_compareStrings(currencyCode, 'EAR')) {
            return amount;
        } else if (_compareStrings(currencyCode, BaseCurrency)) {
            return _getToBase(amount);
        } else if (_compareStrings(currencyCode, 'USD')) {
            return _getToUSD(amount);
        } else {
            return _getToOther(amount, currencyCode);
        }
    }

    function getXToWithHedgeRate(
        uint256 amount,
        string calldata currencyCode,
        uint16 hedgeRate
    ) external view virtual override returns (uint256) {
        uint256 calcHedgeRate = (hedgeRate * (10**(decimals - 2)));
        return getXTo(_multiply(amount, calcHedgeRate, decimals), currencyCode);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(ITokenRate).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _getBaseTo(uint256 amount) internal view virtual returns (uint256) {
        address pairAddress = _getPairAddress(EARAddress, BaseAddress);
        if (pairAddress == address(0)) {
            return 0;
        }
        return _getTokenPrice(pairAddress, amount);
    }

    function _getUSDTo(uint256 amount) internal view virtual returns (uint256) {
        if (address(uniswapFactory) == address(0)) {
            return _multiply(amount, 10**(decimals + 2), decimals); //1USD=100EAR
        }
        (, int256 price, , , ) = USDPriceFeed.latestRoundData();
        uint256 eth =
            _getBaseTo(_division(amount, uint256(price) * (10**(decimals - USDPriceFeed.decimals())), decimals));
        if (eth == 0) {
            return _multiply(amount, 10**(decimals + 2), decimals); //1USD=100EAR
        }
        return eth;
    }

    function _getOtherTo(uint256 amount, string calldata currencyCode) internal view virtual returns (uint256) {
        require(address(rateFeeds[currencyCode]) != address(0), 'EarthaTokenRate: currencyCode is unregistered');
        AggregatorV3Interface rateFeed = rateFeeds[currencyCode];
        (, int256 price, , , ) = rateFeed.latestRoundData();
        uint256 usd = _getUSDTo(uint256(price) * (10**(decimals - rateFeed.decimals())));
        return _multiply(usd, amount, decimals);
    }

    function _getToBase(uint256 amount) internal view virtual returns (uint256) {
        uint256 nowRate = _getBaseTo(1 ether);
        return _division(amount, nowRate, decimals);
    }

    function _getToUSD(uint256 amount) internal view virtual returns (uint256) {
        uint256 nowRate = _getUSDTo(1 ether);
        return _division(amount, nowRate, decimals);
    }

    function _getToOther(uint256 amount, string calldata currencyCode) internal view virtual returns (uint256) {
        uint256 nowRate = _getOtherTo(1 ether, currencyCode);
        return _division(amount, nowRate, decimals);
    }

    function _multiply(
        uint256 a,
        uint256 b,
        uint256 decimals_
    ) internal pure returns (uint256) {
        uint256 result = (a * b) / (10**(decimals_));
        return result;
    }

    function _division(
        uint256 a,
        uint256 b,
        uint256 decimals_
    ) internal pure returns (uint256) {
        uint256 result = ((a * (10**(decimals_))) / (b));
        return result;
    }

    function _compareStrings(string calldata a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function _getPairAddress(address token1, address token2) internal view returns (address) {
        if (address(uniswapFactory) == address(0) || token1 == address(0) || token2 == address(0)) {
            return address(0);
        }
        return uniswapFactory.getPair(token1, token2);
    }

    function _getTokenPrice(address pairAddress, uint256 amount) internal view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint256 Res0, uint256 Res1, ) = pair.getReserves();

        return ((amount * Res0) / Res1);
    }
}
