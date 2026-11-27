#include "phase.hpp"
#include <chrono>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <vector>
#include <sstream>
#include <string>

static std::string bits(double v) {
    unsigned char bytes[8]{};
    std::memcpy(bytes,&v,8);
    std::ostringstream s;
    for (auto b:bytes) s<<std::hex<<std::setw(2)<<std::setfill('0')<<static_cast<unsigned>(b);
    return s.str();
}

int main(int argc, char **argv) {
    if (argc != 3) return 2;
    const uint16_t endian=1;
    if (*reinterpret_cast<const unsigned char*>(&endian)!=1) return 3;
    std::ifstream file(argv[1],std::ios::binary);
    std::vector<apex0722::Input> cases(4108);
    for (auto &in:cases) {
        if (!file.read(reinterpret_cast<char*>(in.data()),7*sizeof(double))) return 4;
        for (double v:in) if (!std::isfinite(v)) return 4;
    }
    if (file.peek()!=std::char_traits<char>::eof()) return 4;
    std::ofstream oracle(argv[2],std::ios::binary);
    for (const auto &in:cases) {
        apex0722::Output out{};
        if (!apex0722::phase(in,out)) return 5;
        oracle.write(reinterpret_cast<const char*>(out.data()),8*sizeof(double));
    }
    oracle.close();
    if (!oracle) return 5;
    constexpr int count=100800;
    std::string expected;
    for (int rep=-1; rep<10; ++rep) {
        const int n=rep<0?10000:count;
        const auto start=std::chrono::steady_clock::now();
        double checksum=0.0;
        for (int i=0;i<n;++i) {
            apex0722::Output out{};
            if (!apex0722::phase(cases[i%cases.size()],out)) return 5;
            for (double v:out) checksum+=v;
        }
        const auto ns=std::chrono::duration_cast<std::chrono::nanoseconds>(
            std::chrono::steady_clock::now()-start).count();
        const auto checksum_bits=bits(checksum);
        if (!std::isfinite(checksum)) return 6;
        if (rep<0) { std::cerr<<"warm checksum "<<checksum_bits<<"\n"; continue; }
        if (rep==0) expected=checksum_bits;
        if (expected!=checksum_bits) return 6;
        std::cout<<std::setprecision(17)<<"APEX_MICRO_ROW {\"mode\":\"pure_cpp\",\"rep\":"
            <<rep<<",\"phases\":"<<n<<",\"elapsed_us\":"<<ns/1000.0
            <<",\"checksum_bits\":\""<<checksum_bits<<"\",\"checksum_finite\":true}\n";
    }
    std::cout<<"APEX_PURE_PASS\n";
}
