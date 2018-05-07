pragma solidity ^0.4.0;

contract Complex {

    uint foo;
    bytes32 foobar;
    bool barFoo;

    event Bar(uint foo, address person);
    event FooBar(bool fooboo, uint foo, bytes32 foobar);

    constructor(uint _foo, bytes32 _foobar) public {
        foo = _foo;
        foobar = _foobar;
    }

    function getBoth() public view returns (uint, bytes32) {
        return (foo, foobar);
    }

    function getBarFoo() public view returns (bool) {
        return barFoo;
    }

    function getFooBar() public view returns (bytes32) {
        return foobar;
    }

    function getFooBoo(uint _fooboo) public pure returns (uint fooBoo) {
        fooBoo = _fooboo + 42;
    }

    function getBroAndBroBro() public view returns (uint bro, bytes32 broBro) {
        return (foo + 42, foobar);
    }

    function setFoo(uint _foo) public {
        foo = _foo;
    }

    function setFooBar(bytes32 _foobar) public {
        foobar = _foobar;
    }

    function setBarFoo(bool _barFoo) public {
        barFoo = _barFoo;
    }
}