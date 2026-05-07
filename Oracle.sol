// Submitted by EthereumHistory (ethereumhistory.com)

contract Oracle {
    mapping(uint => uint16) winningOutcome;

    function setWinningOutcome(uint _targetBlock, uint _lower, uint _upper) {
        uint eventKey = _targetBlock + _lower * (100 * 10**18) + _upper * (10000000000000000000000 * 10**18);
        if (block.number >= _targetBlock && winningOutcome[eventKey] == 0) {
            if (block.difficulty < _lower) {
                winningOutcome[eventKey] = 1;
            } else if (block.difficulty > _upper) {
                winningOutcome[eventKey] = 10001;
            } else {
                winningOutcome[eventKey] = uint16(10000 * (block.difficulty - _lower) / (_upper - _lower));
            }
        }
    }

    function getWinningOutcome(uint _eventKey) constant returns (uint16) {
        return winningOutcome[_eventKey];
    }
}
