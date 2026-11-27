#pragma once
#include <array>
#include <cmath>
#include <limits>

namespace apex0722 {
using Input = std::array<double, 7>;
using Output = std::array<double, 8>;
static_assert(std::numeric_limits<double>::is_iec559 && sizeof(double) == 8,
              "IEEE-754 binary64 required");
// Match Godot 4.7.2 MIN/MAX/CLAMP tie behaviour (including signed zero).
inline double maxf(double a, double b) { return a > b ? a : b; }
inline double minf(double a, double b) { return a < b ? a : b; }
inline double clampf(double a, double lo, double hi) {
    return a < lo ? lo : (a > hi ? hi : a);
}
// Original Vehicle072.phase, not a new sporting model.
// Order: speed, distance, drive, brake, road, net, duration, work.
// A false result is explicit rejection, never a partially valid proposal.
inline bool phase(const Input &in, Output &out) {
    for (double v : in) if (!std::isfinite(v)) return false;
    constexpr double max_mps = 100.0, efficiency = 0.93, eps = 1e-9;
    const double mass = maxf(1.0, in[3]);
    const double start = clampf(in[0], 0.0, max_mps);
    const double duration = maxf(0.0, in[2]);
    const double goal = clampf(in[1], 0.0, max_mps);
    const double road = maxf(0.0, in[4]);
    double drive = 0.0, brake = 0.0;
    if (duration > 0.0) {
        const double request = mass * (goal - start) / duration + road;
        if (!std::isfinite(request)) return false;
        drive = clampf(request, 0.0, maxf(0.0, in[5]));
        brake = clampf(-request, 0.0, maxf(0.0, in[6]));
    }
    const double net = drive - brake - road;
    const double accel = duration > 0.0 ? net / mass : 0.0;
    const double terminal = start + accel * duration;
    if (!std::isfinite(net) || !std::isfinite(accel) || !std::isfinite(terminal)) return false;
    const double end = clampf(terminal, 0.0, max_mps);
    const double ramp = std::abs(accel) > eps
        ? minf(duration, std::abs(end - start) / std::abs(accel)) : duration;
    const double distance = (start + end) * 0.5 * ramp + end * (duration - ramp);
    Output candidate{end, distance, drive, brake, road, net, duration,
                     drive * distance / (1000.0 * efficiency)};
    for (double v : candidate) if (!std::isfinite(v)) return false;
    out = candidate;
    return true;
}
}
