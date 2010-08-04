function st = spm_cfg_st
% SPM Configuration file for Slice Timing Correction
%_______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% $Id: spm_cfg_st.m 4005 2010-07-21 10:54:55Z guillaume $

% ---------------------------------------------------------------------
% scans Session
% ---------------------------------------------------------------------
scans         = cfg_files;
scans.tag     = 'scans';
scans.name    = 'Session';
scans.help    = {'Select images to acquisition correct.'};
scans.filter = 'image';
scans.ufilter = '.*';
scans.num     = [2 Inf];
% ---------------------------------------------------------------------
% generic Data
% ---------------------------------------------------------------------
generic         = cfg_repeat;
generic.tag     = 'generic';
generic.name    = 'Data';
generic.help    = {'Subjects or sessions. The same parameters specified below will be applied to all sessions.'};
generic.values  = {scans };
generic.num     = [1 Inf];
% ---------------------------------------------------------------------
% nslices Number of Slices
% ---------------------------------------------------------------------
nslices         = cfg_entry;
nslices.tag     = 'nslices';
nslices.name    = 'Number of Slices';
nslices.help    = {'Enter the number of slices'};
nslices.strtype = 'n';
nslices.num     = [1 1];
% ---------------------------------------------------------------------
% tr TR
% ---------------------------------------------------------------------
tr         = cfg_entry;
tr.tag     = 'tr';
tr.name    = 'TR';
tr.help    = {'Enter the TR in seconds'};
tr.strtype = 'r';
tr.num     = [1 1];
% ---------------------------------------------------------------------
% ta TA
% ---------------------------------------------------------------------
ta         = cfg_entry;
ta.tag     = 'ta';
ta.name    = 'TA';
ta.help    = {'The TA (in seconds) must be entered by the user. It is usually calculated as TR-(TR/nslices). You can simply enter this equation with the variables replaced by appropriate numbers.'};
ta.strtype = 'e';
ta.num     = [1 1];
% ---------------------------------------------------------------------
% so Slice order
% ---------------------------------------------------------------------
so         = cfg_entry;
so.tag     = 'so';
so.name    = 'Slice order';
so.help    = {
              'Enter the slice order. Bottom slice = 1. Sequence types and examples of code to enter are given below.'
              ''
              'ascending (first slice=bottom): [1:1:nslices]'
              ''
              'descending (first slice=top): [nslices:-1:1]'
              ''
              'interleaved (middle-top):'
              '    for k = 1:nslices,'
              '        round((nslices-k)/2 + (rem((nslices-k),2) * (nslices - 1)/2)) + 1,'
              '    end'
              ''
              'interleaved (bottom -> up): [1:2:nslices 2:2:nslices]'
              ''
              'interleaved (top -> down): [nslices:-2:1, nslices-1:-2:1]'
}';
so.strtype = 'e';
so.num     = [1 Inf];
% ---------------------------------------------------------------------
% refslice Reference Slice
% ---------------------------------------------------------------------
refslice         = cfg_entry;
refslice.tag     = 'refslice';
refslice.name    = 'Reference Slice';
refslice.help    = {'Enter the reference slice'};
refslice.strtype = 'n';
refslice.num     = [1 1];
% ---------------------------------------------------------------------
% prefix Filename Prefix
% ---------------------------------------------------------------------
prefix         = cfg_entry;
prefix.tag     = 'prefix';
prefix.name    = 'Filename Prefix';
prefix.help    = {'Specify the string to be prepended to the filenames of the smoothed image file(s). Default prefix is ''a''.'};
prefix.strtype = 's';
prefix.num     = [1 Inf];
prefix.def     = @(val)spm_get_defaults('slicetiming.prefix', val{:});
% ---------------------------------------------------------------------
% st Slice Timing
% ---------------------------------------------------------------------
st         = cfg_exbranch;
st.tag     = 'st';
st.name    = 'Slice Timing';
st.val     = {generic nslices tr ta so refslice prefix };
st.help    = {
              'Correct differences in image acquisition time between slices. Slice-time corrected files are prepended with an ''a''.'
              ''
              'Note: The sliceorder arg that specifies slice acquisition order is a vector of N numbers, where N is the number of slices per volume. Each number refers to the position of a slice within the image file. The order of numbers within the vector is the temporal order in which those slices were acquired. To check the order of slices within an image file, use the SPM Display option and move the cross-hairs to a voxel co-ordinate of z=1.  This corresponds to a point in the first slice of the volume.'
              ''
              'The function corrects differences in slice acquisition times. This routine is intended to correct for the staggered order of slice acquisition that is used during echo-planar scanning. The correction is necessary to make the data on each slice correspond to the same point in time. Without correction, the data on one slice will represent a point in time as far removed as 1/2 the TR from an adjacent slice (in the case of an interleaved sequence).'
              ''
              'This routine "shifts" a signal in time to provide an output vector that represents the same (continuous) signal sampled starting either later or earlier. This is accomplished by a simple shift of the phase of the sines that make up the signal. Recall that a Fourier transform allows for a representation of any signal as the linear combination of sinusoids of different frequencies and phases. Effectively, we will add a constant to the phase of every frequency, shifting the data in time.'
              ''
              'Shifter - This is the filter by which the signal will be convolved to introduce the phase shift. It is constructed explicitly in the Fourier domain. In the time domain, it may be described as an impulse (delta function) that has been shifted in time the amount described by TimeShift. The correction works by lagging (shifting forward) the time-series data on each slice using sinc-interpolation. This results in each time series having the values that would have been obtained had the slice been acquired at the same time as the reference slice. To make this clear, consider a neural event (and ensuing hemodynamic response) that occurs simultaneously on two adjacent slices. Values from slice "A" are acquired starting at time zero, simultaneous to the neural event, while values from slice "B" are acquired one second later. Without correction, the "B" values will describe a hemodynamic response that will appear to have began one second EARLIER on the "B" slice than on slice "A". To correct for this, the "B" values need to be shifted towards the Right, i.e., towards the last value.'
              ''
              'This correction assumes that the data are band-limited (i.e. there is no meaningful information present in the data at a frequency higher than that of the Nyquist). This assumption is support by the study of Josephs et al (1997, NeuroImage) that obtained event-related data at an effective TR of 166 msecs. No physio-logical signal change was present at frequencies higher than our typical Nyquist (0.25 HZ).'
              ''
              'Written by Darren Gitelman at Northwestern U., 1998.  Based (in large part) on ACQCORRECT.PRO from Geoff Aguirre and Eric Zarahn at U. Penn.'
              ''
              'Note that the authors of SPM do not generally suggest that this correction should be used, but the option is still retained for the few people who like to use it.'
              }';
st.prog = @spm_run_st;
st.vout = @vout;
st.modality = {'FMRI'};
% ---------------------------------------------------------------------

% ---------------------------------------------------------------------
function dep = vout(job)
for k=1:numel(job.scans)
    dep(k)            = cfg_dep;
    dep(k).sname      = sprintf('Slice Timing Corr. Images (Sess %d)', k);
    dep(k).src_output = substruct('()',{k}, '.','files');
    dep(k).tgt_spec   = cfg_findspec({{'filter','image','strtype','e'}});
end
return;
