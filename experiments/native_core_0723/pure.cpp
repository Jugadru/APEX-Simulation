#include "phase.hpp"
#include <chrono>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <vector>
#include <sstream>
#include <string>
int main(int argc, char **argv) {
    if (argc != 2) return 2;
    std::ifstream file(argv[1]);
    std::vector<apex0722::Input> cases;
    std::string line;
    while (std::getline(file,line)) {
        std::istringstream stream(line);
        apex0722::Input in{};
        for (double &v : in) if (!(stream >> v)) return 3;
        cases.push_back(in);
    }
    if (cases.size() != 4108) return 4;
    constexpr int count=100800;
    double expected=0.0;
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
        if (rep<0) { std::cerr<<"warm checksum "<<checksum<<"\n"; continue; }
        if (rep==0) expected=checksum;
        if (expected!=checksum || !std::isfinite(checksum)) return 6;
        std::cout<<std::setprecision(17)<<"APEX_MICRO_ROW {\"mode\":\"pure_cpp\",\"rep\":"
            <<rep<<",\"phases\":"<<n<<",\"elapsed_us\":"<<ns/1000.0
            <<",\"checksum\":"<<checksum<<"}\n";
    }
    std::cout<<"APEX_PURE_PASS\n";
}
