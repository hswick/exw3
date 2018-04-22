<p align="center">
  <img src="./exw3_logo.jpg"/>
</p>

## Installation

  1. Add exw3 to your list of dependencies in mix.exs:

        def deps do
          [{:exw3, "~> 0.0.1"}]
        end

  2. Ensure exw3 is started before your application:

        def application do
          [applications: [:exw3]]
        end

# Compiling solidity

Ensure you have solc installed:

```
solc --version
```

Then if you've made changes to the example contracts you can compile them like this:
```
solc -o test/examples/build --abi --bin test/examples/contracts/* --overwrite
```