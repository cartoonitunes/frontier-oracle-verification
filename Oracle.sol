// Submitted by EthereumHistory (ethereumhistory.com)
//
// Pre-Gnosis prediction market resolution oracle
// Address:   0x33cA8b5377c9776eb59863Fb63814dc00a5CB10D
// Deployer:  0x77b97786b0fb73e55d9e92d4b182befbf346f979 (Stefan George)
// Deployed:  2015-08-12  (block 76165, tx 0xc9f378d160ea94f514a1c166c7221930f6492e7f53055e1c19e51a631cda2bca)
// Compiler:  solc 0.1.0 (frontier-jul29 native C++), no optimizer
// Verified:  full creation bytecode (496 bytes) byte-for-byte match
//
// This is the world's earliest known on-chain prediction-market oracle.
// It resolves bets on ETH mining difficulty using block.difficulty as the input.
// Companion contracts by the same deployer in the same week:
//   - 0xe376... fixed-point math library
//   - 0xdb7c577b93baeb56dab50af4d6f86f99a06b96a2  LMSR market maker (behemoth)

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
