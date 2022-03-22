/// @title  HTLC to release USDT from investor to issuer
/// @dev    Contract for DVP. Investor funds this contract with his usdt and gets the security token in exchange.

pragma solidity 0.8.10;

import "../utils/IERC20.sol";


contract HTLC20 {


    mapping(bytes32 => OrderSwap) private _orderSwap;      //  map the order struct to the order ID
    mapping(bytes32 => SwapState) private _swapState;      //  to keep track of the swap state of an id
    address _owner;

    IERC20 ERC20_TOKEN;

    struct OrderSwap {

        
        address _recipient;
        address _investor;
        uint256 _price;
        uint256 _expiration;
        bytes32 _secretHash;
        bytes32 _secretKey;
        bytes32 _swapID;
        bool _funded;
        
    }


    enum SwapState {

        INVALID,
        OPEN,
        CLOSED,
        EXPIRED

    }

    constructor(address _usdtAddress) {

        ERC20_TOKEN = IERC20(_usdtAddress);
        _owner = msg.sender;

    }

    /// @dev    Issuer initializes the order with the same orderID in the htlc1400 contract
    /// @dev    The issuer uses the ID to withdraw USDT from this contract, while the investor uses the ID to withdraw from the htlc1400 contract
    /// @param  _swapID is the ID of the swap order. This ID must be valid on the htlc1400 contract for swap to occur
    /// @param _investor is the address that will fund this contract with the given _swapID
    /// @param  _price is the price of the security token to be purchased. This contract is funded by investor for this particular order
    /// @param _expiration is the time expected for this order to expire before a refund can enabled
    /// @param _secretHash is the hash of the secret set on this contract and htlc1400 for this particular swap ID

    function createOrder(bytes32 _swapID, address _investor, uint256 _price, uint256 _expiration, bytes32 _secretHash) {

        require(msg.sender == _owner, "invalid caller");
        require(_swapState[_swapID] == SwapState.INVALID, "this order id exist already");
        _orderSwap[_swapID] = OrderSwap(msg.sender, _investor, _price, _expiration, _secretHash, bytes(0), _swapID, false);
        _swapState[_swapID] = SwapState.OPEN;
        emit OpenedOrder(_investor, _swapID, _price, expiration, _secretHash);

    }


    /// @param _swapID is the id of the order to be funded
    /// @notice `_orderSwap[_swapID]._funded == false`, i.e the order must not be funded yet
    /// @notice `_swapState[_swapID] == SwapState.OPEN` ,  i.e the order state must be opened
    /// @dev this contract must be approved by the caller before calling this function

    function fundOrder(bytes32 _swapID) external {

        require(_swapState[_swapID] == SwapState.OPEN, "this order isn't opened");
        require(_orderSwap[_swapID]._funded == false, "this order has been funded");
        require(_orderSwap[_swapID]._investor == msg.sender, "invalid caller");
        OrderSwap memory _order = _orderSwap[_swapID];
        ERC20_TOKEN.transferFrom(_order._investor, address(this), _order._price);
        emit Funded(_order._investor, _order._price);

    }


    /// @param _swapID is the id of the order to withdrawn the usdt from
    /// @param _secretKey is the secret the issuer must provide and reveal to the investor. The investor will in turn use this secret to withdraw the security token from the htlc1400 contract
    /// @notice the caller is the owner of the contract
    /// @notice the order must be OPEN
    /// @notice the order must not be an expired order

    function issuerWithdrawal(bytes32 _swapID, bytes32 _secretKey) {

        require(msg.sender == _owner, "invalid caller");
        require(_swapState[_swapID] == SwapState.OPEN, "this order is not opened");
        OrderSwap memory _order = _orderSwap[_swapID];
        require(block.timestamp < _order._expiration, "order has expired");
        ERC20_TOKEN.transfer(_order._recipient, _order._price);
        _swapState[_swapID] = SwapState.CLOSED;
        emit ClosedOrder(_order._investor, _swapID, _order._price, _order._expiration, _order._secretHash);



    }

    event OpenedOrder(address indexed _investor, bytes32 _swapID, uint256 _amount, uint256 _expiration, bytes32 _secretHash);
    event ClosedOrder(address indexed _investor, bytes32 _swapID, uint256 _amount,bytes32 _secretKey, bytes32 _secretHash);
    event RefundOrder(address indexed _to, bytes32 _swapID, uint256 _amount, uint256 _expiration);
    event Funded(address indexed _investor, uint256 _price);

}