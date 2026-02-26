(defvar vasp-incar-tags
  '( "ADDGRID"  "AEXX"  "AGGAC"  "AGGAX"  "ALDAC"  "ALGO"  "AMIN"  "AMIX"  "AMIX_MAG"  "ANDERSEN_PROB"
     "ANTIRES"  "APACO"  "BMIX"  "BMIX_MAG"  "CH_LSPEC"  "CH_NEDOS"  "CH_SIGMA"  "CLL"  "CLN"  "CLNT"
     "CLZ"  "CMBJ"  "CMBJA"  "CMBJB"  "CSHIFT"  "DEPER"  "DIMER_DIST"  "DIPOL"  "DQ"  "EBREAK"
     "EDIFF"  "EDIFFG"  "EFIELD"  "EFIELD_PEAD"  "EINT"  "EMAX"  "EMIN"  "ENAUG"  "ENCUT"  "ENCUTFOCK"
     "ENCUTGW"  "ENCUTGWSOFT"  "ENINI"  "EPSILON"  "ESTOP"  "EVENONLY"  "EVENONLYGW"  "FERDO"  "FERWE"  "FINDIFF"
     "GGA"  "GGA_COMPAT"  "HFALPHA"  "HFLMAX"  "HFRCUT"  "HFSCREEN"  "HILLS_BIN"  "HILLS_H"  "HILLS_W"  "HITOLER"
     "I_CONSTRAINED_M"  "IALGO"  "IBAND"  "IBRION"  "ICHARG"  "ICHIBARE"  "ICORELEVEL"  "IDIPOL"  "IEPSILON"  "IGPAR"
     "IMAGES"  "IMIX"  "INCREM"  "INIMIX"  "INIWAV"  "IPEAD"  "ISIF"  "ISMEAR"  "ISPIN"  "ISTART"
     "ISYM"  "IVDW"  "IWAVPR"  "KBLOCK"  "KGAMMA"  "KPAR"  "KPOINT_BSE"  "KPUSE"  "KSPACING"  "LADDER"
     "LAECHG"  "LAMBDA"  "LANGEVIN_GAMMA"  "LANGEVIN_GAMMA_L"  "LASPH"  "LASYNC"  "LATTICE_CONSTRAINTS"  "LBERRY"  "LBLUEOUT"  "LBONE"
     "LCALCEPS"  "LCALCPOL"  "LCHARG"  "LCHIMAG"  "LCORR"  "LDAU"  "LDAUJ"  "LDAUL"  "LDAUPRINT"  "LDAUTYPE"
     "LDAUU"  "LDIAG"  "LDIPOL"  "LEFG"  "LELF"  "LEPSILON"  "LFINITE_TEMPERATURE"  "LFOCKACE"  "LFOCKAEDFT"  "LHARTREE"
     "LHFCALC"  "LHYPERFINE"  "LKPROJ"  "LLRAUG"  "LMAXFOCK"  "LMAXFOCKAE"  "LMAXMIX"  "LMAXPAW"  "LMAXTAU"  "LMIXTAU"
     "LMODELHF"  "LMONO"  "LMP2LT"  "LNABLA"  "LNMR_SYM_RED"  "LNONCOLLINEAR"  "LOCPROJ"  "LOPTICS"  "LORBIT"  "LORBMOM"
     "LPARD"  "LPEAD"  "LPLANE"  "LREAL"  "LRPA"  "LSCAAWARE"  "LSCALAPACK"  "LSCALU"  "LSCSGRAD"  "LSELFENERGY"
     "LSEPB"  "LSEPK"  "LSMP2LT"  "LSORBIT"  "LSPECTRAL"  "LSPECTRALGW"  "LSPIRAL"  "LSUBROT"  "LTHOMAS"  "LUSE_VDW"
     "LVDW_EWALD"  "LVDW_ONECELL"  "LVDWEXPANSION"  "LVHAR"  "LVTOT"  "LWANNIER90"  "LWANNIER90_RUN"  "LWAVE"  "LWRITE_MMN_AMN"  "LWRITE_UNK"
     "LWRITE_WANPROJ"  "LZEROZ"  "M_CONSTR"  "MAGMOM"  "MAXMEM"  "MAXMIX"  "MDALGO"  "METAGGA"  "MINROT"  "MIXPRE"
     "ML_AFILT2"  "ML_CDOUB"  "ML_CSIG"  "ML_CSLOPE"  "ML_CTIFOR"  "ML_CX"  "ML_EATOM_REF"  "ML_EPS_LOW"  "ML_IAFILT2"  "ML_IALGO_LINREG"
     "ML_ICOUPLE"  "ML_ICRITERIA"  "ML_IREG"  "ML_ISCALE_TOTEN"  "ML_ISTART"  "ML_IWEIGHT"  "ML_LAFILT2"  "ML_LCOUPLE"  "ML_LEATOM"  "ML_LHEAT"
     "ML_LMAX2"  "ML_LMLFF"  "ML_LSPARSDES"  "ML_MB"  "ML_MCONF"  "ML_MCONF_NEW"  "ML_MHIS"  "ML_MRB1"  "ML_MRB2"  "ML_NATOM_COUPLED"
     "ML_NHYP"  "ML_NMDINT"  "ML_NRANK_SPARSDES"  "ML_RCOUPLE"  "ML_RCUT1"  "ML_RCUT2"  "ML_RDES_SPARSDES"  "ML_SIGV0"  "ML_SIGW0"  "ML_SION1"
     "ML_SION2"  "ML_W1"  "ML_WTIFOR"  "ML_WTOTEN"  "ML_WTSIF"  "NATURALO"  "NBANDS"  "NBANDSGW"  "NBANDSO"  "NBANDSV"
     "NBLK"  "NBLOCK"  "NBMOD"  "NBSEEIG"  "NCORE"  "NCORE_IN_IMAGE1"  "NCRPA_BANDS"  "NEDOS"  "NELECT"  "NELM"
     "NELMDL"  "NELMIN"  "NFREE"  "NGX"  "NGXF"  "NGY"  "NGYF"  "NGYROMAG"  "NGZ"  "NGZF"
     "NKRED"  "NKREDX"  "NKREDY"  "NKREDZ"  "NLSPLINE"  "NMAXFOCKAE"  "NOMEGA"  "NOMEGAPAR"  "NOMEGAR"  "NPACO"
     "NPAR"  "NPPSTR"  "NRMM"  "NSIM"  "NSTORB"  "NSUBSYS"  "NSW"  "NTARGET_STATES"  "NTAUPAR"  "NUPDOWN"
     "NWRITE"  "ODDONLY"  "ODDONLYGW"  "OFIELD_A"  "OFIELD_KAPPA"  "OFIELD_Q6_FAR"  "OFIELD_Q6_NEAR"  "OMEGAMAX"  "OMEGAMIN"  "OMEGATL"
     "PARAM1"  "PARAM2"  "PFLAT"  "PHON_LBOSE"  "PHON_LMC"  "PHON_NSTRUCT"  "PHON_NTLIST"  "PHON_TLIST"  "PLEVEL"  "PMASS"
     "POMASS"  "POTIM"  "PREC"  "PRECFOCK"  "PROUTINE"  "PSTRESS"  "PSUBSYS"  "PTHRESHOLD"  "QMAXFOCKAE"  "QSPIRAL"
     "QUAD_EFG"  "RANDOM_SEED"  "ROPT"  "RWIGS"  "SAXIS"  "SCALEE"  "SCSRAD"  "SHAKEMAXITER"  "SHAKETOL"  "SIGMA"
     "SMASS"  "SMEARINGS"  "SPRING"  "STEP_MAX"  "STEP_SIZE"  "SYMPREC"  "SYSTEM"  "TEBEG"  "TEEND"  "TIME"
     "TSUBSYS"  "VALUE_MAX"  "VALUE_MIN"  "VCA"  "VCAIMAGES"  "VCUTOFF"  "VDW_A1"  "VDW_A2"  "VDW_C6"  "VDW_CNRADIUS"
     "VDW_D"  "VDW_R0"  "VDW_RADIUS"  "VDW_S6"  "VDW_S8"  "VDW_SR"  "VOSKOWN"  "WC"  "WEIMIN"  "ZVAL" 
     ))

(defvar vasp-incar-bools
  '(".FALSE." "FALSE" ".TRUE." "TRUE"))



;; Two small edits.
;; First is to put an extra set of parens () around the list
;; which is the format that font-lock-defaults wants
;; Second, you used ' (quote) at the outermost level where you wanted ` (backquote)
;; you were very close
(defvar vasp-font-lock-keywords
  `(
    ;; stuff between double quotes
    ("\".*?\"" . font-lock-string-face)
    ;; ; = are all special elements
    (";\\|=" . font-lock-string-face)
    ( ,(regexp-opt vasp-incar-tags 'words) . font-lock-keyword-face)
    ( ,(regexp-opt vasp-incar-bools 'words) . font-lock-warning-face)))




(define-derived-mode vasp-mode fundamental-mode "VASP inout"
  "VASP mode is a major mode for handling in/out put of VASP code"

  (setq-local font-lock-defaults (list vasp-font-lock-keywords nil nil))

  ;; when there's an override, use it
  ;; otherwise it gets the default value
  
  ;; (setq indent-tabs-mode nil)
  ;; (setq tab-width nil)
  ;; for comments
  
  ;; A normal comment setup avoids `comment-normalize-vars` errors.
  (setq-local comment-start "# ")
  (setq-local comment-start-skip "#+\\s-*")
  (setq-local comment-end "")
  ;; (indent-line-to 0)
  (highlight-lines-matching-regexp "band\\s-" 'hi-green-b)
  (highlight-lines-matching-regexp "k-point\\s-" 'homoglyph)
  (highlight-lines-matching-regexp "TITEL" 'hi-green)
  (highlight-lines-matching-regexp "TOTEN" 'hi-red-b)
  (highlight-lines-matching-regexp "Iteration" 'hi-aquamarine)
  (highlight-lines-matching-regexp "TOTAL-FORCE" 'hi-red-b)
  (highlight-lines-matching-regexp "external pressure" 'hi-red-b)
  (highlight-lines-matching-regexp "magnetization" 'hi-red-b)
  (highlight-lines-matching-regexp "LEXCH" 'hi-red-b)


  (modify-syntax-entry ?# "< b" vasp-mode-syntax-table)
  (modify-syntax-entry ?\n "> b" vasp-mode-syntax-table)

  ;; Note that there's no need to manually call `mydsl-mode-hook'; `define-derived-mode'
  ;; will define `mydsl-mode' to call it properly right before it exits
  )

;; (add-hook 'vasp-mode-hook
;; 	  (lambda () (local-set-key (kbd <"tab">) 'delete-indentation)))
(provide 'vasp-mode)
