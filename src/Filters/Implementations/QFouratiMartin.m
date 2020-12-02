% This algorithm comes from paper:
%
% A nonlinear filtering approach for the attitude and dynamic body acceleration estimation based on inertial and magnetic sensors: Bio-logging application,
% H. Fourati, N. Manamanni, L. Afilal, Y. Handrich
% IEEE Sensors Journal, VOL. 11, NO. 1, January 2011
% https://hal.archives-ouvertes.fr/hal-00624142/
%
% and
%
% Heterogeneous Data Fusion Algorithm for Pedestrian Navigation via Foot-Mounted Inertial Measurement Unit and Complementary Filter
% H. Fourati
% IEEE Transactions on Instrumentation and Measurement, Institute of Electrical and Electronics Engineers, 2015, 64 (1), pp.221-229
% https://hal.inria.fr/hal-00999073
%
% It has been implemented by H. Fourati and modified by T. Michel.
%
% This work is a part of project "On Attitude Estimation with Smartphones"
% http://tyrex.inria.fr/mobile/benchmarks-attitude
%
% Contact :
% Thibaud Michel
% thibaud.michel@gmail.com

classdef QFouratiMartin < AttitudeFilter

    properties (Access = private)
        Beta = 0.3;
        Ka = 2;
        Kc = 1;
    end

    properties (Access = private)
        CRef;
        CRefNormalized;
    end

    methods (Access = public)

        function q = update(obj, gyr, acc, mag, dT)

            q = obj.quaternion;

            acc = acc / norm(acc);
            mag = mag / norm(mag);
            c = cross(acc, mag);
            c = c / norm(c);

            estimate_A = quatrotate(q, obj.AccRefNormalized);
            estimate_C = quatrotate(q, obj.CRefNormalized);

            Measure = [acc c];
            Estimate = [estimate_A estimate_C];
            delta = 2 * [obj.Ka * skew(estimate_A); obj.Kc * skew(estimate_C)]';

            % Gradient decent algorithm corrective step
            dq = (Measure - Estimate) * ((delta * delta' + 1e-5 * eye(3))^ - 1 * delta)';

            qDot = 0.5 * quatmultiply(q, [0 gyr]) + obj.Beta * quatmultiply(q, [0 dq]);
            q = q + qDot * dT;
            q = q / norm(q);

            obj.quaternion = q;
        end

        function notifyReferenceVectorChanged(obj)

            notifyReferenceVectorChanged@AttitudeFilter(obj)

            obj.CRef = cross(obj.AccRef, obj.MagRef);
            obj.CRefNormalized = obj.CRef / norm(obj.CRef);

        end

        function setParams(obj, params)
            obj.Beta = params(1);
            obj.Ka = params(2);
            obj.Kc = params(3);
        end

    end

end
