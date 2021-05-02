pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./Wallet.sol";

contract Dex is Wallet {

    using SafeMath for uint256;
    
    enum Side {
        BUY,
        SELL
    }

    struct Order {
        uint id;
        address trader;
        bool buyOrder;
        bytes32 ticker;
        uint amount;
        uint price;
    }
    
    uint public nextOrderId = 0;

    mapping(bytes32 => mapping(uint => Order[])) public orderBook;

    function getOrderBook(bytes32 ticker, Side side) view public returns(Order[] memory) {
        return orderBook[ticker][uint(side)];
    }

    function createLimitOrder(Side side, bytes32 ticker, uint amount, uint price) public {
        if (side == Side.BUY) {
            require(balances[msg.sender]["ETH"] >= amount.mul(price), "Not enough ETH balance");
            Order[] storage orders = orderBook[ticker][uint(side)];
            orders.push(Order(nextOrderId, msg.sender, true, ticker, amount, price));

            for (uint i = orders.length - 1; i > 0; --i) {
                if (orders[i].price > orders[i - 1].price) {
                    Order memory prev = orders[i - 1];
                    orders[i - 1] = orders[i];
                    orders[i] = prev;
                }
            }
        }
        else {
            require(balances[msg.sender][ticker] >= amount, "Not enough token balance");
            Order[] storage orders = orderBook[ticker][uint(side)];
            orders.push(Order(nextOrderId, msg.sender, false, ticker, amount, price));

            for (uint i = orders.length - 1; i > 0; --i) {
                if (orders[i].price < orders[i - 1].price) {
                    Order memory prev = orders[i - 1];
                    orders[i - 1] = orders[i];
                    orders[i] = prev;
                }
            }
        }
        
        nextOrderId++;
    }
}