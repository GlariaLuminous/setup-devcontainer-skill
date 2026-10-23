module example.com/go-mod-fixture

// Declares an older minimum than the container's toolchain on purpose: a real
// project usually does, and it keeps the fixture buildable with whatever Go a
// contributor happens to have installed. verify.sh asserts the container
// toolchain version separately.
go 1.23
