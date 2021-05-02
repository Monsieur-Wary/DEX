pragma solidity >=0.7.0 <0.8.0;
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
        Side side;
        bytes32 ticker;
        uint amount;
        uint price;
        uint filled;
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
            orders.push(Order(nextOrderId, msg.sender, side, ticker, amount, price, 0));

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
            orders.push(Order(nextOrderId, msg.sender, side, ticker, amount, price, 0));

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

    function createMarketOrder(Side side, bytes32 ticker, uint amount) public{
        if(side == Side.SELL){
            require(balances[msg.sender][ticker] >= amount, "Insuffient balance");
        }
        
        uint orderBookSide = side == Side.BUY ? 1 : 0;
        Order[] storage orders = orderBook[ticker][orderBookSide];

        uint totalFilled = 0;

        for (uint256 i = 0; i < orders.length && totalFilled < amount; i++) {
            uint leftToFill = amount.sub(totalFilled);
            uint availableToFill = orders[i].amount.sub(orders[i].filled);
            uint filled = availableToFill > leftToFill ? leftToFill : availableToFill;

            totalFilled = totalFilled.add(filled);
            orders[i].filled = orders[i].filled.add(filled);
            uint cost = filled.mul(orders[i].price);

            if(side == Side.BUY){
                require(balances[msg.sender]["ETH"] >= cost);
                balances[msg.sender][ticker] = balances[msg.sender][ticker].add(filled);
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].sub(cost);
                
                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].sub(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].add(cost);
            }
            else {
                balances[msg.sender][ticker] = balances[msg.sender][ticker].sub(filled);
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].add(cost);
                
                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].add(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].sub(cost);
            }
            
        }

        // FIXME: Ineficient
        while(orders.length > 0 && orders[0].filled == orders[0].amount){
            for (uint256 i = 0; i < orders.length - 1; i++) {
                orders[i] = orders[i + 1];
            }
            orders.pop();
        }
        
    }
}