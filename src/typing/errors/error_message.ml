(**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open Type
open Reason
open Utils_js

exception EDebugThrow of ALoc.t
exception EMergeTimeout of float

type invalid_char_set =
  | DuplicateChar of Char.t
  | InvalidChar of Char.t

module InvalidCharSetSet = Set.Make(struct
  type t = invalid_char_set
  let compare = Pervasives.compare
end)

type t =
  | EIncompatible of {
      lower: reason * lower_kind option;
      upper: reason * upper_kind;
      use_op: use_op option;
      branches: (Reason.t * t) list;
    }
  | EIncompatibleDefs of {
      use_op: use_op;
      reason_lower: reason;
      reason_upper: reason;
      branches: (Reason.t * t) list;
    }
  | EIncompatibleProp of {
      prop: string option;
      reason_prop: reason;
      reason_obj: reason;
      special: lower_kind option;
      use_op: use_op option;
    }
  | EDebugPrint of reason * string
  | EImportValueAsType of reason * string
  | EImportTypeAsTypeof of reason * string
  | EImportTypeAsValue of reason * string
  | ERefineAsValue of reason * string
  | ENoDefaultExport of reason * string * string option
  | EOnlyDefaultExport of reason * string * string
  | ENoNamedExport of reason * string * string * string option
  | EMissingTypeArgs of { reason_tapp: reason; reason_arity: reason; min_arity: int; max_arity: int }
  | EValueUsedAsType of (reason * reason)
  | EExpectedStringLit of (reason * reason) * string * string Type.literal * use_op
  | EExpectedNumberLit of
      (reason * reason) *
      Type.number_literal *
      Type.number_literal Type.literal *
      use_op
  | EExpectedBooleanLit of (reason * reason) * bool * bool option * use_op
  | EPropNotFound of string option * (reason * reason) * use_op
  | EPropAccess of (reason * reason) * string option * Type.polarity * Type.rw * use_op
  | EPropPolarityMismatch of (reason * reason) * string option * (Type.polarity * Type.polarity) * use_op
  | EPolarityMismatch of {
      reason: reason;
      name: string;
      expected_polarity: Type.polarity;
      actual_polarity: Type.polarity;
    }
  | EStrictLookupFailed of (reason * reason) * reason * string option * use_op option
  | EPrivateLookupFailed of (reason * reason) * string * use_op
  | EAdditionMixed of reason * use_op
  | EComparison of (reason * reason)
  | ETupleArityMismatch of (reason * reason) * int * int * use_op
  | ENonLitArrayToTuple of (reason * reason) * use_op
  | ETupleOutOfBounds of (reason * reason) * int * int * use_op
  | ETupleUnsafeWrite of (reason * reason) * use_op
  | EUnionSpeculationFailed of {
      use_op: use_op;
      reason: reason;
      reason_op: reason;
      branches: (reason * t) list;
    }
  | ESpeculationAmbiguous of (reason * reason) * (int * reason) * (int * reason) * reason list
  | EIncompatibleWithExact of (reason * reason) * use_op
  | EUnsupportedExact of (reason * reason)
  | EIdxArity of reason
  | EIdxUse1 of reason
  | EIdxUse2 of reason
  | EUnexpectedThisType of ALoc.t
  | ETypeParamArity of ALoc.t * int
  | ECallTypeArity of {
      call_loc: ALoc.t;
      is_new: bool;
      reason_arity: reason;
      expected_arity: int;
    }
  | ETypeParamMinArity of ALoc.t * int
  | ETooManyTypeArgs of reason * reason * int
  | ETooFewTypeArgs of reason * reason * int
  | EInvalidTypeArgs of reason * reason
  | EPropertyTypeAnnot of ALoc.t
  | EExportsAnnot of ALoc.t
  | ECharSetAnnot of ALoc.t
  | EInvalidCharSet of { invalid: reason * InvalidCharSetSet.t; valid: reason; use_op: use_op }
  | EUnsupportedKeyInObjectType of ALoc.t
  | EPredAnnot of ALoc.t
  | ERefineAnnot of ALoc.t
  | ETrustedAnnot of ALoc.t
  | EPrivateAnnot of ALoc.t
  | EUnexpectedTypeof of ALoc.t
  | EFunPredCustom of (reason * reason) * string
  | EIncompatibleWithShape of reason * reason * use_op
  | EInternal of ALoc.t * internal_error
  | EUnsupportedSyntax of ALoc.t * unsupported_syntax
  | EUseArrayLiteral of ALoc.t
  | EMissingAnnotation of reason * reason list
  | EBindingError of binding_error * ALoc.t * string * Scope.Entry.t
  | ERecursionLimit of (reason * reason)
  | EModuleOutsideRoot of ALoc.t * string
  | EMalformedPackageJson of ALoc.t * string
  | EExperimentalDecorators of ALoc.t
  | EExperimentalClassProperties of ALoc.t * bool
  | EUnsafeGetSet of ALoc.t
  | EExperimentalExportStarAs of ALoc.t
  | EIndeterminateModuleType of ALoc.t
  | EBadExportPosition of ALoc.t
  | EBadExportContext of string * ALoc.t
  | EUnreachable of ALoc.t
  | EInvalidObjectKit of { tool: Object.tool; reason: reason; reason_op: reason; use_op: use_op }
  | EInvalidTypeof of ALoc.t * string
  | EBinaryInLHS of reason
  | EBinaryInRHS of reason
  | EArithmeticOperand of reason
  | EForInRHS of reason
  | EObjectComputedPropertyAccess of (reason * reason)
  | EObjectComputedPropertyAssign of (reason * reason)
  | EInvalidLHSInAssignment of ALoc.t
  | EIncompatibleWithUseOp of reason * reason * use_op
  | EUnsupportedImplements of reason
  | EReactKit of (reason * reason) * React.tool * use_op
  | EReactElementFunArity of reason * string * int
  | EFunctionCallExtraArg of reason * reason * int * use_op
  | EUnsupportedSetProto of reason
  | EDuplicateModuleProvider of {
      module_name: string;
      provider: File_key.t;
      conflict: File_key.t
    }
  | EParseError of ALoc.t * Parse_error.t
  | EDocblockError of ALoc.t * docblock_error
  (* The string is either the name of a module or "the module that exports `_`". *)
  | EUntypedTypeImport of ALoc.t * string
  | EUntypedImport of ALoc.t * string
  | ENonstrictImport of ALoc.t
  | EUnclearType of ALoc.t
  | EDeprecatedType of ALoc.t
  | EDeprecatedUtility of ALoc.t * string
  | EDynamicExport of reason * reason
  | EUnsafeGettersSetters of ALoc.t
  | EUnusedSuppression of ALoc.t
  | ELintSetting of LintSettings.lint_parse_error
  | ESketchyNullLint of {
      kind: Lints.sketchy_null_kind;
      loc: ALoc.t;
      null_loc: ALoc.t;
      falsy_loc: ALoc.t;
    }
  | ESketchyNumberLint of Lints.sketchy_number_kind * reason
  | EInvalidPrototype of reason
  | EExperimentalOptionalChaining of ALoc.t
  | EOptionalChainingMethods of ALoc.t
  | EUnnecessaryOptionalChain of ALoc.t * reason
  | EUnnecessaryInvariant of ALoc.t * reason
  | EInexactSpread of reason * reason
  | EDeprecatedCallSyntax of ALoc.t
  | EUnexpectedTemporaryBaseType of ALoc.t
  | ESignatureVerification of Signature_builder_deps.With_ALoc.Error.t

and binding_error =
  | ENameAlreadyBound
  | EReferencedBeforeDeclaration
  | ETypeInValuePosition
  | ETypeAliasInValuePosition
  | EConstReassigned
  | EConstParamReassigned
  | EImportReassigned

and docblock_error =
  | MultipleFlowAttributes
  | MultipleProvidesModuleAttributes
  | MultipleJSXAttributes
  | InvalidJSXAttribute of string option

and internal_error =
  | PackageHeapNotFound of string
  | AbnormalControlFlow
  | MethodNotAFunction
  | OptionalMethod
  | OpenPredWithoutSubst
  | PredFunWithoutParamNames
  | UnsupportedGuardPredicate of string
  | BreakEnvMissingForCase
  | PropertyDescriptorPropertyCannotBeRead
  | ForInLHS
  | ForOfLHS
  | InstanceLookupComputed
  | PropRefComputedOpen
  | PropRefComputedLiteral
  | ShadowReadComputed
  | ShadowWriteComputed
  | RestParameterNotIdentifierPattern
  | InterfaceTypeSpread
  | DebugThrow
  | MergeTimeout of float
  | MergeJobException of Exception.t
  | UnexpectedTypeapp of string

and unsupported_syntax =
  | ComprehensionExpression
  | GeneratorExpression
  | MetaPropertyExpression
  | ObjectPropertyLiteralNonString
  | ObjectPropertyGetSet
  | ObjectPropertyComputedGetSet
  | InvariantSpreadArgument
  | ClassPropertyLiteral
  | ClassPropertyComputed
  | ReactCreateClassPropertyNonInit
  | RequireDynamicArgument
  | RequireLazyDynamicArgument
  | CatchParameterAnnotation
  | CatchParameterDeclaration
  | DestructuringObjectPropertyLiteralNonString
  | DestructuringExpressionPattern
  | PredicateDeclarationForImplementation
  | PredicateDeclarationWithoutExpression
  | PredicateDeclarationAnonymousParameters
  | PredicateInvalidBody
  | PredicateVoidReturn
  | MultipleIndexers
  | SpreadArgument
  | ImportDynamicArgument
  | IllegalName
  | UnsupportedInternalSlot of { name: string; static: bool }

and lower_kind =
  | Possibly_null
  | Possibly_void
  | Possibly_null_or_void
  | Incompatible_intersection

and upper_kind =
  | IncompatibleGetPropT of ALoc.t * string option
  | IncompatibleSetPropT of ALoc.t * string option
  | IncompatibleMatchPropT of ALoc.t * string option
  | IncompatibleGetPrivatePropT
  | IncompatibleSetPrivatePropT
  | IncompatibleMethodT of ALoc.t * string option
  | IncompatibleCallT
  | IncompatibleMixedCallT
  | IncompatibleConstructorT
  | IncompatibleGetElemT of ALoc.t
  | IncompatibleSetElemT of ALoc.t
  | IncompatibleCallElemT of ALoc.t
  | IncompatibleElemTOfArrT
  | IncompatibleObjAssignFromTSpread
  | IncompatibleObjAssignFromT
  | IncompatibleObjRestT
  | IncompatibleObjSealT
  | IncompatibleArrRestT
  | IncompatibleSuperT
  | IncompatibleMixinT
  | IncompatibleSpecializeT
  | IncompatibleThisSpecializeT
  | IncompatibleVarianceCheckT
  | IncompatibleGetKeysT
  | IncompatibleHasOwnPropT of ALoc.t * string option
  | IncompatibleGetValuesT
  | IncompatibleUnaryMinusT
  | IncompatibleMapTypeTObject
  | IncompatibleTypeAppVarianceCheckT
  | IncompatibleGetStaticsT
  | IncompatibleUnclassified of string

let desc_of_reason r = Reason.desc_of_reason ~unwrap:(is_scalar_reason r) r

(* A utility function for getting and updating the use_op in error messages. *)
let util_use_op_of_msg nope util = function
| EIncompatible {use_op; lower; upper; branches} ->
  Option.value_map use_op ~default:nope ~f:(fun use_op ->
    util use_op (fun use_op ->
      EIncompatible {use_op=Some use_op; lower; upper; branches}))
| EIncompatibleDefs {use_op; reason_lower; reason_upper; branches} ->
  util use_op (fun use_op ->
    EIncompatibleDefs {use_op; reason_lower; reason_upper; branches})
| EIncompatibleProp {use_op; prop; reason_prop; reason_obj; special} ->
  Option.value_map use_op ~default:nope ~f:(fun use_op ->
    util use_op (fun use_op ->
      EIncompatibleProp {use_op=Some use_op; prop; reason_prop; reason_obj; special}))
| EExpectedStringLit (rs, u, l, op) -> util op (fun op -> EExpectedStringLit (rs, u, l, op))
| EExpectedNumberLit (rs, u, l, op) -> util op (fun op -> EExpectedNumberLit (rs, u, l, op))
| EExpectedBooleanLit (rs, u, l, op) -> util op (fun op -> EExpectedBooleanLit (rs, u, l, op))
| EPropNotFound (prop, rs, op) -> util op (fun op -> EPropNotFound (prop, rs, op))
| EPropAccess (rs, prop, p, rw, op) -> util op (fun op -> EPropAccess (rs, prop, p, rw, op))
| EPropPolarityMismatch (rs, p, ps, op) -> util op (fun op -> EPropPolarityMismatch (rs, p, ps, op))
| EStrictLookupFailed (rs, r, p, Some op) ->
  util op (fun op -> EStrictLookupFailed (rs, r, p, Some op))
| EPrivateLookupFailed (rs, x, op) -> util op (fun op -> EPrivateLookupFailed (rs, x, op))
| EAdditionMixed (r, op) -> util op (fun op -> EAdditionMixed (r, op))
| ETupleArityMismatch (rs, x, y, op) -> util op (fun op -> ETupleArityMismatch (rs, x, y, op))
| ENonLitArrayToTuple (rs, op) -> util op (fun op -> ENonLitArrayToTuple (rs, op))
| ETupleOutOfBounds (rs, l, i, op) -> util op (fun op -> ETupleOutOfBounds (rs, l, i, op))
| ETupleUnsafeWrite (rs, op) -> util op (fun op -> ETupleUnsafeWrite (rs, op))
| EUnionSpeculationFailed {use_op; reason; reason_op; branches} ->
  util use_op (fun use_op -> EUnionSpeculationFailed {use_op; reason; reason_op; branches})
| EIncompatibleWithExact (rs, op) -> util op (fun op -> EIncompatibleWithExact (rs, op))
| EInvalidCharSet {invalid; valid; use_op} ->
  util use_op (fun use_op -> EInvalidCharSet {invalid; valid; use_op})
| EIncompatibleWithShape (l, u, use_op) ->
  util use_op (fun use_op -> EIncompatibleWithShape (l, u, use_op))
| EInvalidObjectKit {tool; reason; reason_op; use_op} ->
  util use_op (fun use_op -> EInvalidObjectKit {tool; reason; reason_op; use_op})
| EIncompatibleWithUseOp (rl, ru, op) -> util op (fun op -> EIncompatibleWithUseOp (rl, ru, op))
| EReactKit (rs, t, op) -> util op (fun op -> EReactKit (rs, t, op))
| EFunctionCallExtraArg (rl, ru, n, op) -> util op (fun op -> EFunctionCallExtraArg (rl, ru, n, op))
| EDebugPrint (_, _)
| EImportValueAsType (_, _)
| EImportTypeAsTypeof (_, _)
| EImportTypeAsValue (_, _)
| ERefineAsValue (_, _)
| ENoDefaultExport (_, _, _)
| EOnlyDefaultExport (_, _, _)
| ENoNamedExport (_, _, _, _)
| EMissingTypeArgs {reason_tapp=_; reason_arity=_; min_arity=_; max_arity=_}
| EValueUsedAsType (_, _)
| EPolarityMismatch {reason=_; name=_; expected_polarity=_; actual_polarity=_}
| EStrictLookupFailed (_, _, _, None)
| EComparison (_, _)
| ESpeculationAmbiguous (_, _, _, _)
| EUnsupportedExact (_, _)
| EIdxArity (_)
| EIdxUse1 (_)
| EIdxUse2 (_)
| EUnexpectedThisType (_)
| ETypeParamArity (_, _)
| ECallTypeArity _
| ETypeParamMinArity (_, _)
| ETooManyTypeArgs (_, _, _)
| ETooFewTypeArgs (_, _, _)
| EInvalidTypeArgs (_, _)
| EPropertyTypeAnnot (_)
| EExportsAnnot (_)
| ECharSetAnnot (_)
| EUnsupportedKeyInObjectType (_)
| EPredAnnot (_)
| ERefineAnnot (_)
| ETrustedAnnot (_)
| EPrivateAnnot (_)
| EUnexpectedTypeof (_)
| EFunPredCustom (_, _)
| EInternal (_, _)
| EUnsupportedSyntax (_, _)
| EUseArrayLiteral (_)
| EMissingAnnotation (_)
| EBindingError (_, _, _, _)
| ERecursionLimit (_, _)
| EModuleOutsideRoot (_, _)
| EMalformedPackageJson (_, _)
| EExperimentalDecorators (_)
| EExperimentalClassProperties (_, _)
| EUnsafeGetSet (_)
| EExperimentalExportStarAs (_)
| EIndeterminateModuleType (_)
| EBadExportPosition (_)
| EBadExportContext (_)
| EUnreachable (_)
| EInvalidTypeof (_, _)
| EBinaryInLHS (_)
| EBinaryInRHS (_)
| EArithmeticOperand (_)
| EForInRHS (_)
| EObjectComputedPropertyAccess (_, _)
| EObjectComputedPropertyAssign (_, _)
| EInvalidLHSInAssignment (_)
| EUnsupportedImplements (_)
| EReactElementFunArity (_, _, _)
| EUnsupportedSetProto (_)
| EDuplicateModuleProvider {module_name=_; provider=_; conflict=_}
| EParseError (_, _)
| EDocblockError (_, _)
| EUntypedTypeImport (_, _)
| EUntypedImport (_, _)
| ENonstrictImport (_)
| EUnclearType (_)
| EDeprecatedType _
| EDeprecatedUtility _
| EDynamicExport _
| EUnsafeGettersSetters (_)
| EUnusedSuppression (_)
| ELintSetting (_)
| ESketchyNullLint {kind=_; loc=_; null_loc=_; falsy_loc=_}
| ESketchyNumberLint _
| EInvalidPrototype (_)
| EExperimentalOptionalChaining _
| EOptionalChainingMethods _
| EUnnecessaryOptionalChain _
| EUnnecessaryInvariant _
| EInexactSpread _
| EDeprecatedCallSyntax _
| EUnexpectedTemporaryBaseType _
| ESignatureVerification _
  -> nope

(* Not all messages (i.e. those whose locations are based on use_ops) have locations that can be
  determined while locations are abstract. We just return None in this case. *)
let aloc_of_msg : t -> ALoc.t option = function
  | EValueUsedAsType (primary, _)
  | EComparison (primary, _)
  | EFunPredCustom ((primary, _), _)
  | EDynamicExport (_, primary)
  | EInexactSpread (_, primary)
  | EInvalidTypeArgs (_, primary)
  | ETooFewTypeArgs (primary, _, _)
  | ETooManyTypeArgs (primary, _, _) ->
      Some (aloc_of_reason primary)
  | ESketchyNumberLint (_, reason)
  | EInvalidPrototype reason
  | EUnsupportedSetProto reason
  | EReactElementFunArity (reason, _, _)
  | EUnsupportedImplements reason
  | EObjectComputedPropertyAssign (_, reason)
  | EObjectComputedPropertyAccess (_, reason)
  | EForInRHS reason
  | EBinaryInRHS reason
  | EBinaryInLHS reason
  | EArithmeticOperand reason
  | ERecursionLimit (reason, _)
  | EMissingAnnotation (reason, _)
  | EIdxArity reason
  | EIdxUse1 reason
  | EIdxUse2 reason
  | EUnsupportedExact (_, reason)
  | EPolarityMismatch { reason; _ }
  | ENoNamedExport (reason, _, _, _)
  | EOnlyDefaultExport (reason, _, _)
  | ENoDefaultExport (reason, _, _)
  | ERefineAsValue (reason, _)
  | EImportTypeAsValue (reason, _)
  | EImportTypeAsTypeof (reason, _)
  | EImportValueAsType (reason, _)
  | EDebugPrint (reason, _) ->
        Some (aloc_of_reason reason)
  | EUntypedTypeImport (loc, _)
  | EUntypedImport (loc, _)
  | ENonstrictImport loc
  | EUnclearType loc
  | EDeprecatedType loc
  | EDeprecatedUtility (loc, _)
  | EUnsafeGettersSetters loc
  | EDeprecatedCallSyntax loc
  | EUnnecessaryOptionalChain (loc, _)
  | EUnnecessaryInvariant (loc, _)
  | EOptionalChainingMethods loc
  | EExperimentalOptionalChaining loc
  | EUnusedSuppression loc
  | EDocblockError (loc, _)
  | EParseError (loc, _)
  | EInvalidLHSInAssignment loc
  | EInvalidTypeof (loc, _)
  | EUnreachable loc
  | EUnexpectedTemporaryBaseType loc
  | EBadExportContext (_, loc)
  | EBadExportPosition loc
  | EIndeterminateModuleType loc
  | EExperimentalExportStarAs loc
  | EUnsafeGetSet loc
  | EExperimentalClassProperties (loc, _)
  | EExperimentalDecorators loc
  | EModuleOutsideRoot (loc, _)
  | EMalformedPackageJson (loc, _)
  | EUseArrayLiteral loc
  | EUnsupportedSyntax (loc, _)
  | EInternal (loc, _)
  | EUnexpectedTypeof loc
  | EPrivateAnnot loc
  | ETrustedAnnot loc
  | ERefineAnnot loc
  | EPredAnnot loc
  | EUnsupportedKeyInObjectType loc
  | ECharSetAnnot loc
  | EExportsAnnot loc
  | EPropertyTypeAnnot loc
  | EUnexpectedThisType loc
  | ETypeParamMinArity (loc, _) -> Some loc
  | ELintSetting (loc, _) -> Some (ALoc.of_loc loc)
  | ETypeParamArity (loc, _) ->
      Some loc
  | ESketchyNullLint { loc; _ } ->
      Some loc
  | ECallTypeArity { call_loc; _} ->
      Some call_loc
  | EMissingTypeArgs { reason_tapp; _ } ->
      Some (aloc_of_reason reason_tapp)
  | ESignatureVerification sve ->
      Signature_builder_deps.With_ALoc.Error.(match sve with
        | ExpectedSort (_, _, loc)
        | ExpectedAnnotation loc
        | InvalidTypeParamUse loc
        | UnexpectedObjectKey (loc, _)
        | UnexpectedObjectSpread (loc, _)
        | UnexpectedArraySpread (loc, _)
        | UnexpectedArrayHole loc
        | EmptyArray loc
        | EmptyObject loc
        | UnexpectedExpression (loc, _)
        | SketchyToplevelDef loc
        | TODO (_, loc) ->               Some loc
      )
  | EDuplicateModuleProvider {conflict; _ } ->
      let loc1 = Loc.(
        let pos = { line = 1; column = 0; } in
        { source = Some conflict; start = pos; _end = pos }
      ) in
      Some (ALoc.of_loc loc1)
  | EBindingError (_, loc, _, _) -> Some loc
  | ESpeculationAmbiguous ((union_r, _), _, _, _) -> Some (aloc_of_reason union_r)
  | EStrictLookupFailed ((reason, _), lreason, _, _) when is_builtin_reason lreason ->
      Some (aloc_of_reason reason)
  | EFunctionCallExtraArg _
  | EReactKit _
  | EIncompatibleWithUseOp _
  | EIncompatibleDefs _
  | EInvalidObjectKit _
  | EIncompatibleWithShape _
  | EInvalidCharSet _
  | EIncompatibleWithExact _
  | EUnionSpeculationFailed _
  | ETupleUnsafeWrite _
  | ETupleOutOfBounds _
  | ENonLitArrayToTuple _
  | ETupleArityMismatch _
  | EAdditionMixed _
  | EPrivateLookupFailed _
  | EStrictLookupFailed _
  | EPropPolarityMismatch _
  | EPropAccess _
  | EPropNotFound _
  | EExpectedBooleanLit _
  | EExpectedNumberLit _
  | EExpectedStringLit _
  | EIncompatibleProp _
  | EIncompatible _ -> None

let kind_of_msg = Errors.(function
  | EUntypedTypeImport _            -> LintError Lints.UntypedTypeImport
  | EUntypedImport _                -> LintError Lints.UntypedImport
  | ENonstrictImport _              -> LintError Lints.NonstrictImport
  | EUnclearType _                  -> LintError Lints.UnclearType
  | EDeprecatedType _               -> LintError Lints.DeprecatedType
  | EDeprecatedUtility _            -> LintError Lints.DeprecatedUtility
  | EDynamicExport _                -> LintError Lints.DynamicExport
  | EUnsafeGettersSetters _         -> LintError Lints.UnsafeGettersSetters
  | EDeprecatedCallSyntax _         -> LintError Lints.DeprecatedCallSyntax
  | ESketchyNullLint { kind; _ }    -> LintError (Lints.SketchyNull kind)
  | ESketchyNumberLint (kind, _)    -> LintError (Lints.SketchyNumber kind)
  | EUnnecessaryOptionalChain _     -> LintError Lints.UnnecessaryOptionalChain
  | EUnnecessaryInvariant _         -> LintError Lints.UnnecessaryInvariant
  | EInexactSpread _                -> LintError Lints.InexactSpread
  | ESignatureVerification _        -> LintError Lints.SignatureVerificationFailure
  | EUnexpectedTypeof _
  | EExperimentalDecorators _
  | EExperimentalClassProperties _
  | EUnsafeGetSet _
  | EExperimentalExportStarAs _
  | EIndeterminateModuleType _
  | EBadExportPosition _
  | EBadExportContext _
  | EUnreachable _
  | EInvalidTypeof _                -> InferWarning
  | EInternal _                     -> InternalError
  | ERecursionLimit _               -> RecursionLimitError
  | EDuplicateModuleProvider _      -> DuplicateProviderError
  | EParseError _
  | EDocblockError _
  | ELintSetting _
  | EExperimentalOptionalChaining _
  | EOptionalChainingMethods _      -> ParseError
  | _ -> InferError
)

let mk_prop_message = Errors.Friendly.(function
  | None | Some "$key" | Some "$value" -> [text "an indexer property"]
  | Some "$call" -> [text "a callable signature"]
  | Some prop -> [text "property "; code prop]
)

(* Friendly messages are created differently based on the specific error they come from, so
   we collect the ingredients here and pass them to make_error_printable *)
type friendly_message_recipe =
  | IncompatibleUse of ALoc.t * upper_kind * Reason.reason * Type.use_op
  | Speculation of ALoc.t * Type.use_op * (Reason.t * t) list
  | Incompatible of Reason.reason * Reason.reason * Type.use_op
  | PropMissing of ALoc.t * string option * Reason.reason * Type.use_op
  | Normal of ALoc.t Errors.Friendly.message_feature list
  | UseOp of ALoc.t * ALoc.t Errors.Friendly.message_feature list * Type.use_op
  | PropPolarityMismatch of string option *
      (Reason.reason * Type.polarity) * (Reason.reason * Type.polarity) * Type.use_op

let friendly_message_of_msg : t -> friendly_message_recipe =
  let text = Errors.Friendly.text in
  let code = Errors.Friendly.code in
  let ref = Errors.Friendly.ref in
  let desc = Errors.Friendly.ref ~loc:false in

  let msg_export export_name =
    if export_name = "default" then
      text "the default export"
    else
      code export_name
  in

  Errors.(function
    | EIncompatible {
        lower = (reason_lower, _);
        upper = (reason_upper, upper_kind);
        use_op;
        branches;
      } ->
      if branches = [] then
        IncompatibleUse
          (aloc_of_reason reason_upper, upper_kind, reason_lower, Option.value ~default:unknown_use use_op)
      else
        Speculation (aloc_of_reason reason_upper, Option.value ~default:unknown_use use_op, branches)

    | EIncompatibleDefs { use_op; reason_lower; reason_upper; branches } ->
      if branches = [] then
        Incompatible (reason_lower, reason_upper, use_op)
      else
        Speculation (aloc_of_reason reason_upper, use_op, branches)

    | EIncompatibleProp { prop; reason_prop; reason_obj; special=_; use_op } ->
      PropMissing
        (aloc_of_reason reason_prop, prop, reason_obj, Option.value ~default:unknown_use use_op)

    | EDebugPrint (_, str) ->
      Normal [text str]

    | EImportValueAsType (_, export_name) ->
      Normal [
        text "Cannot import the value "; msg_export export_name; text " as a type. ";
        code "import type"; text " only works on type exports. Like type aliases, ";
        text "interfaces, and classes. If you intended to import the type of a ";
        text "value use "; code "import typeof"; text " instead.";
      ]

    | EImportTypeAsTypeof (_, export_name) ->
      Normal [
        text "Cannot import the type "; msg_export export_name; text " as a type. ";
        code "import typeof"; text " only works on value exports. Like variables, ";
        text "functions, and classes. If you intended to import a type use ";
        code "import type"; text " instead.";
      ]

    | EImportTypeAsValue (_, export_name) ->
      Normal [
        text "Cannot import the type "; msg_export export_name; text " as a value. ";
        text "Use "; code "import type"; text " instead.";
      ]

    | ERefineAsValue (_, name) ->
      Normal [
        text "Cannot refine "; msg_export name; text " as a value. ";
        (* text "Use "; code "import type"; text " instead."; *)
      ]

    | ENoDefaultExport (_, module_name, suggestion) ->
      Normal (
        [
          text "Cannot import a default export because there is no default export ";
          text "in "; code module_name; text ".";
        ] @
        match suggestion with
        | None -> []
        | Some suggestion -> [text " ";
            text "Did you mean ";
            code (spf "import {%s} from \"%s\"" suggestion module_name);
            text "?";
          ]
      )

    | EOnlyDefaultExport (_, module_name, export_name) ->
      Normal [
        text "Cannot import "; code export_name; text " because ";
        text "there is no "; code export_name; text " export in ";
        code module_name; text ". Did you mean ";
        code (spf "import %s from \"...\"" export_name); text "?";
      ]

    | ENoNamedExport (_, module_name, export_name, suggestion) ->
      Normal (
        [
          text "Cannot import "; code export_name; text " because ";
          text "there is no "; code export_name; text " export in ";
          code module_name; text ".";
        ] @
        match suggestion with
        | None -> []
        | Some suggestion -> [text " Did you mean "; code suggestion; text "?"]
      )

    | EMissingTypeArgs { reason_tapp; reason_arity; min_arity; max_arity } ->
      let arity, args =
        if min_arity = max_arity then
          spf "%d" max_arity, if max_arity = 1 then "argument" else "arguments"
        else
          spf "%d-%d" min_arity max_arity, "arguments"
      in
      let reason_arity = replace_reason_const (desc_of_reason reason_tapp) reason_arity in
      Normal
        [text "Cannot use "; ref reason_arity; text (spf " without %s type %s." arity args)]

    | ETooManyTypeArgs (reason_tapp, reason_arity, n) ->
      let reason_arity = replace_reason_const (desc_of_reason reason_tapp) reason_arity in
      Normal [
        text "Cannot use "; ref reason_arity; text " with more than ";
        text (spf "%n type %s." n (if n == 1 then "argument" else "arguments"))
      ]

    | ETooFewTypeArgs (reason_tapp, reason_arity, n) ->
      let reason_arity = replace_reason_const (desc_of_reason reason_tapp) reason_arity in
      Normal [
        text "Cannot use "; ref reason_arity; text " with fewer than ";
        text (spf "%n type %s." n (if n == 1 then "argument" else "arguments"))
      ]

    | EInvalidTypeArgs (reason_main, reason_tapp) ->
      Normal [
        text "Cannot use "; ref reason_main; text " with "; ref reason_tapp; text " argument";
      ]

    | ETypeParamArity (_, n) ->
      if n = 0 then
        Normal
          [text "Cannot apply type because it is not a polymorphic type."]
      else
        Normal [
          text "Cannot use type without exactly ";
          text (spf "%n type %s." n (if n == 1 then "argument" else "arguments"));
        ]

    | ETypeParamMinArity (_, n) ->
      Normal [
        text "Cannot use type without at least ";
        text (spf "%n type %s." n (if n == 1 then "argument" else "arguments"));
      ]

    | ECallTypeArity { call_loc=_; is_new; reason_arity; expected_arity = n } ->
      let use = if is_new then "construct " else "call " in
      if n = 0 then
        Normal [
          text "Cannot "; text use; text "non-polymorphic "; ref reason_arity;
          text " with type arguments.";
        ]
      else
        Normal [
          text "Cannot "; text use; ref reason_arity; text " without exactly ";
          text (spf "%n type argument%s." n (if n == 1 then "" else "s"));
        ]

    | EValueUsedAsType reasons ->
      let (value, _) = reasons in
      Normal [
        text "Cannot use "; desc value; text " as a type because ";
        desc value; text " is a value. To get the type of ";
        text "a value use "; code "typeof"; text ".";
      ]

    | EExpectedStringLit (reasons, _, _, use_op) ->
      let (reason_lower, reason_upper) = reasons in
      Incompatible (reason_lower, reason_upper, use_op)

    | EExpectedNumberLit (reasons, _, _, use_op) ->
      let (reason_lower, reason_upper) = reasons in
      Incompatible (reason_lower, reason_upper, use_op)

    | EExpectedBooleanLit (reasons, _, _, use_op) ->
      let (reason_lower, reason_upper) = reasons in
      Incompatible (reason_lower, reason_upper, use_op)

    | EPropNotFound (prop, reasons, use_op) ->
      let (reason_prop, reason_obj) = reasons in
      PropMissing
        (aloc_of_reason reason_prop, prop, reason_obj, use_op)

    | EPropAccess (reasons, x, _, rw, use_op) ->
      let (reason_prop, _) = reasons in
      let rw = match rw with
      | Read -> "readable"
      | Write _ -> "writable"
      in
      UseOp (aloc_of_reason reason_prop, mk_prop_message x @ [text (spf " is not %s" rw)], use_op)

    | EPropPolarityMismatch (reasons, x, (p1, p2), use_op) ->
      let (lreason, ureason) = reasons in
      PropPolarityMismatch
        (x, (lreason, p1), (ureason, p2), use_op)

    | EPolarityMismatch { reason; name; expected_polarity; actual_polarity } ->
      let polarity_string = function
      | Positive -> "output"
      | Negative -> "input"
      | Neutral -> "input/output"
      in
      let expected_polarity = polarity_string expected_polarity in
      let actual_polarity = polarity_string actual_polarity in
      let reason_targ = mk_reason (RIdentifier name) (def_aloc_of_reason reason) in
      Normal [
        text "Cannot use "; ref reason_targ; text (" in an " ^ actual_polarity ^ " ");
        text "position because "; ref reason_targ; text " is expected to occur only in ";
        text (expected_polarity ^ " positions.");
      ]

    | EStrictLookupFailed (reasons, lreason, x, use_op) ->
      (* if we're looking something up on the global/builtin object, then tweak
         the error to say that `x` doesn't exist. We can tell this is the
         global object because that should be the only object created with
         `builtin_reason` instead of an actual location (see `Init_js.init`). *)
      if is_builtin_reason lreason then
        let (reason, _) = reasons in
        let msg = match x with
        | Some x when is_internal_module_name x ->
          [text "Cannot resolve module "; code (uninternal_module_name x); text "."]
        | None -> [text "Cannot resolve name "; desc reason; text "."]
        | Some x when is_internal_name x -> [text "Cannot resolve name "; desc reason; text "."]
        | Some x -> [text "Cannot resolve name "; code x; text "."]
        in
        Normal msg
      else
        let (reason_prop, reason_obj) = reasons in
        PropMissing
          (aloc_of_reason reason_prop, x, reason_obj, Option.value ~default:unknown_use use_op)

    | EPrivateLookupFailed (reasons, x, use_op) ->
      PropMissing
        (aloc_of_reason (fst reasons), Some ("#" ^ x), snd reasons, use_op)

    | EAdditionMixed (reason, use_op) ->
      UseOp (aloc_of_reason reason,
        [ref reason; text " could either behave like a string or like a number"],
        use_op)

    | EComparison (lower, upper) ->
      Normal
        [text "Cannot compare "; ref lower; text " to "; ref upper; text "."]

    | ETupleArityMismatch (reasons, l1, l2, use_op) ->
      let (lower, upper) = reasons in
      UseOp (aloc_of_reason lower, [
        ref lower; text (spf " has an arity of %d but " l1); ref upper;
        text (spf " has an arity of %d" l2);
      ], use_op)

    | ENonLitArrayToTuple (reasons, use_op) ->
      let (lower, upper) = reasons in
      UseOp (aloc_of_reason lower, [
        ref lower; text " has an unknown number of elements, so is ";
        text "incompatible with "; ref upper;
      ], use_op)

    | ETupleOutOfBounds (reasons, length, index, use_op) ->
      let (lower, upper) = reasons in
      UseOp (aloc_of_reason lower, [
        ref upper;
        text (spf " only has %d element%s, so index %d is out of bounds"
          length (if length == 1 then "" else "s") index);
      ], use_op)

    | ETupleUnsafeWrite (reasons, use_op) ->
      let (lower, _) = reasons in
      UseOp (aloc_of_reason lower,
        [text "the index must be statically known to write a tuple element"],
        use_op)

    | EUnionSpeculationFailed { use_op; reason; reason_op=_; branches } ->
      Speculation (aloc_of_reason reason, use_op, branches)

    | ESpeculationAmbiguous (_, (prev_i, prev_case), (i, case), case_rs) ->
      let open Friendly in
      let prev_case_r =
        mk_reason (RCustom
          ("case " ^ string_of_int (prev_i + 1))) (aloc_of_reason prev_case)
      in
      let case_r =
        mk_reason (RCustom
          ("case " ^ string_of_int (i + 1))) (aloc_of_reason case)
      in
      Normal (
        [
          text "Could not decide which case to select. Since "; ref prev_case_r; text " ";
          text "may work but if it doesn't "; ref case_r; text " looks promising ";
          text "too. To fix add a type annotation ";
        ] @
        (conjunction_concat ~conjunction:"or" (Core_list.map ~f:(fun case_r ->
          let text = "to " ^ (string_of_desc (desc_of_reason case_r)) in
          [ref (mk_reason (RCustom text) (aloc_of_reason case_r))]
        ) case_rs)) @
        [text "."]
      )

    | EIncompatibleWithExact (reasons, use_op) ->
      let (lower, upper) = reasons in
      UseOp (aloc_of_reason lower,
        [text "inexact "; ref lower; text " is incompatible with exact "; ref upper],
        use_op
      )

    | EUnsupportedExact (_, lower) ->
      Normal
        [text "Cannot create exact type from "; ref lower; text "."]

    | EIdxArity _ ->
      Normal [
        text "Cannot call "; code "idx(...)"; text " because only exactly two ";
        text "arguments are allowed."
      ]

    | EIdxUse1 _ ->
      Normal [
        text "Cannot call "; code "idx(...)"; text " because the callback ";
        text "argument must not be annotated.";
      ]

    | EIdxUse2 _ ->
      Normal [
        text "Cannot call "; code "idx(...)"; text " because the callback must ";
        text "only access properties on the callback parameter.";
      ]

    | EUnexpectedThisType _ ->
      Normal
        [text "Unexpected use of "; code "this"; text " type."]

    | EPropertyTypeAnnot _ ->
      Normal [
        text "Cannot use "; code "$PropertyType"; text " because the second ";
        text "type argument must be a string literal.";
      ]

    | EExportsAnnot _ ->
      Normal [
        text "Cannot use "; code "$Exports"; text " because the first type ";
        text "argument must be a string literal.";
      ]

    | ECharSetAnnot _ ->
      Normal [
        text "Cannot use "; code "$CharSet"; text " because the first type ";
        text "argument must be a string literal.";
      ]

    | EInvalidCharSet {
        invalid = (invalid_reason, invalid_chars);
        valid = valid_reason;
        use_op;
      } ->
      let valid_reason = mk_reason (desc_of_reason valid_reason) (def_aloc_of_reason valid_reason) in
      let invalids =
        InvalidCharSetSet.fold (fun c acc ->
          match c with
          | InvalidChar c ->
            [code (String.make 1 c); text " is not a member of the set"] :: acc
          | DuplicateChar c ->
            [code (String.make 1 c); text " is duplicated"] :: acc
        ) invalid_chars []
        |> List.rev
      in
      UseOp (
        aloc_of_reason invalid_reason,
        [ref invalid_reason; text " is incompatible with "; ref valid_reason; text " since "] @
        Friendly.conjunction_concat ~conjunction:"and" invalids,
        use_op
      )

    | EUnsupportedKeyInObjectType _ ->
      Normal
        [text "Unsupported key in object type."]

    | EPredAnnot _ ->
      Normal [
        text "Cannot use "; code "$Pred"; text " because the first ";
        text "type argument must be a number literal.";
      ]

    | ERefineAnnot _ ->
      Normal [
        text "Cannot use "; code "$Refine"; text " because the third ";
        text "type argument must be a number literal.";
      ]

    | ETrustedAnnot _ ->
      Normal [
        text "Not a valid type to mark as "; code "$Trusted"; text ".";
      ]

    | EPrivateAnnot _ ->
      Normal [
        text "Not a valid type to mark as "; code "$Private"; text ".";
      ]

    | EUnexpectedTypeof _ ->
      Normal
        [code "typeof"; text " can only be used to get the type of variables."]

    | EFunPredCustom ((a, b), msg) ->
      Normal
        [ref a; text ". "; text msg; text " "; ref b; text "."]

    | EIncompatibleWithShape (lower, upper, use_op) ->
      UseOp (aloc_of_reason lower, [
        ref lower; text " is incompatible with "; code "$Shape"; text " of ";
        ref upper;
      ], use_op)

    | EInternal (_, internal_error) ->
      let msg = match internal_error with
      | PackageHeapNotFound pkg ->
          spf "package %S was not found in the PackageHeap!" pkg
      | AbnormalControlFlow ->
          "abnormal control flow"
      | MethodNotAFunction ->
          "expected function type"
      | OptionalMethod ->
          "optional methods are not supported"
      | OpenPredWithoutSubst ->
          "OpenPredT ~> OpenPredT without substitution"
      | PredFunWithoutParamNames ->
          "FunT -> FunT no params"
      | UnsupportedGuardPredicate pred ->
          spf "unsupported guard predicate (%s)" pred
      | BreakEnvMissingForCase ->
          "break env missing for case"
      | PropertyDescriptorPropertyCannotBeRead ->
          "unexpected property in properties object"
      | ForInLHS ->
          "unexpected LHS in for...in"
      | ForOfLHS ->
          "unexpected LHS in for...of"
      | InstanceLookupComputed ->
          "unexpected computed property lookup on InstanceT"
      | PropRefComputedOpen ->
          "unexpected open computed property element type"
      | PropRefComputedLiteral ->
          "unexpected literal computed property element type"
      | ShadowReadComputed ->
          "unexpected shadow read on computed property"
      | ShadowWriteComputed ->
          "unexpected shadow write on computed property"
      | RestParameterNotIdentifierPattern ->
          "unexpected rest parameter, expected an identifier pattern"
      | InterfaceTypeSpread ->
          "unexpected spread property in interface"
      | DebugThrow ->
          "debug throw"
      | MergeTimeout s ->
          spf "merge job timed out after %0.2f seconds" s
      | MergeJobException exc ->
          "uncaught exception: "^(Exception.to_string exc)
      | UnexpectedTypeapp s ->
          "unexpected typeapp: "^s
      in
      Normal [text (spf "Internal error: %s" msg)]

    | EUnsupportedSyntax (_, unsupported_syntax) ->
      let msg = match unsupported_syntax with
        | ComprehensionExpression
        | GeneratorExpression
        | MetaPropertyExpression ->
          [text "Not supported."]
        | ObjectPropertyLiteralNonString ->
          [text "Non-string literal property keys not supported."]
        | ObjectPropertyGetSet ->
          [text "Get/set properties not yet supported."]
        | ObjectPropertyComputedGetSet ->
          [text "Computed getters and setters are not yet supported."]
        | InvariantSpreadArgument ->
          [text "Unsupported arguments in call to "; code "invariant"; text "."]
        | ClassPropertyLiteral ->
          [text "Literal properties not yet supported."]
        | ClassPropertyComputed ->
          [text "Computed property keys not supported."]
        | ReactCreateClassPropertyNonInit ->
          [text "Unsupported property specification in "; code "createClass"; text "."]
        | RequireDynamicArgument ->
          [text "The parameter passed to "; code "require"; text " must be a string literal."]
        | ImportDynamicArgument ->
          [text "The parameter passed to "; code "import"; text " must be a string literal."]
        | RequireLazyDynamicArgument -> [
            text "The first argument to "; code "requireLazy"; text " must be an ";
            text "array literal of string literals and the second argument must ";
            text "be a callback.";
          ]
        | CatchParameterAnnotation ->
          [text "Type annotations for catch parameters are not yet supported."]
        | CatchParameterDeclaration ->
          [text "Unsupported catch parameter declaration."]
        | DestructuringObjectPropertyLiteralNonString ->
          [text "Unsupported non-string literal object property in destructuring."]
        | DestructuringExpressionPattern ->
          [text "Unsupported expression pattern in destructuring."]
        | PredicateDeclarationForImplementation ->
          [text "Cannot declare predicate when a function body is present."]
        | PredicateDeclarationWithoutExpression -> [
            text "Predicate function declarations need to declare a ";
            text "predicate expression."
          ]
        | PredicateDeclarationAnonymousParameters -> [
            text "Predicate function declarations cannot use anonymous ";
            text "function parameters.";
          ]
        | PredicateInvalidBody -> [
            text "Invalid body for predicate function. Expected a simple return ";
            text "statement as body."
          ]
        | PredicateVoidReturn ->
          [text "Predicate functions need to return non-void."]
        | MultipleIndexers ->
          [text "Multiple indexers are not supported."]
        | SpreadArgument ->
          [text "A spread argument is unsupported here."]
        | IllegalName ->
          [text "Illegal name."]
        | UnsupportedInternalSlot {name; static = false} ->
          [text "Unsupported internal slot "; code name; text "."]
        | UnsupportedInternalSlot {name; static = true} ->
          [text "Unsupported static internal slot "; code name; text "."]
      in
      Normal msg

    | EUseArrayLiteral _ ->
      Normal
        [text "Use an array literal instead of "; code "new Array(...)"; text "."]

    | EMissingAnnotation (reason, _) ->
      let default = [text "Missing type annotation for "; desc reason; text "."] in
      let msg = match (desc_of_reason reason) with
      | RTypeParam (_, (RImplicitInstantiation, _), _) ->
          [text "Please use a concrete type annotation instead of "; code "_";
        text " in this position."]
      | RTypeParam (_, (reason_op_desc, reason_op_loc), (reason_tapp_desc, reason_tapp_loc)) ->
          let reason_op = mk_reason reason_op_desc reason_op_loc in
          let reason_tapp = mk_reason reason_tapp_desc reason_tapp_loc in
          default @ [text " "; desc reason; text " is a type parameter declared in "; ref reason_tapp;
           text " and was implicitly instantiated at "; ref reason_op; text "."]
      | _ -> default in

      (* We don't collect trace info in the assert_ground_visitor because traces
       * represent tests of lower bounds to upper bounds, and the assert_ground
       * visitor is just visiting types. Instead, we collect a list of types we
       * visited to get to the missing annotation error and report that as the
       * trace *)
      Normal msg

    | EBindingError (binding_error, _, x, entry) ->
      let desc =
        if x = internal_name "this" then RThis
        else if x = internal_name "super" then RSuper
        else RIdentifier x
      in
      let x = mk_reason desc (Scope.Entry.entry_loc entry) in
      let msg = match binding_error with
      | ENameAlreadyBound ->
        [text "Cannot declare "; ref x; text " because the name is already bound."]
      | EReferencedBeforeDeclaration ->
        if desc = RThis || desc = RSuper then [
          text "Must call "; code "super"; text " before accessing "; ref x;
          text " in a derived constructor."
        ] else [
          text "Cannot use variable "; ref x; text " because the declaration ";
          text "either comes later or was skipped.";
        ]
      | ETypeInValuePosition
      | ETypeAliasInValuePosition
        -> [text "Cannot reference type "; ref x; text " from a value position."]
      | EConstReassigned
      | EConstParamReassigned
        -> [text "Cannot reassign constant "; ref x; text "."]
      | EImportReassigned ->
        [text "Cannot reassign import "; ref x; text "."]
      in
      Normal msg

    | ERecursionLimit _ ->
      Normal
        [text "*** Recursion limit exceeded ***"]

    | EModuleOutsideRoot (_, package_relative_to_root) ->
      Normal [
        text "This module resolves to "; code package_relative_to_root; text " which ";
        text "is outside both your root directory and all of the entries in the ";
        code "[include]"; text " section of your "; code ".flowconfig"; text ". ";
        text "You should either add this directory to the "; code "[include]"; text " ";
        text "section of your "; code ".flowconfig"; text ", move your ";
        code ".flowconfig"; text " file higher in the project directory tree, or ";
        text "move this package under your Flow root directory.";
      ]

    | EMalformedPackageJson (_, error) ->
        Normal [
          text error;
        ]

    | EExperimentalDecorators _ ->
      Normal [
        text "Experimental decorator usage. Decorators are an early stage ";
        text "proposal that may change. Additionally, Flow does not account for ";
        text "the type implications of decorators at this time.";
      ]

    | EExperimentalClassProperties (_, static) ->
      let config_name, config_key =
        if static
        then "class static field", "class_static_fields"
        else "class instance field", "class_instance_fields"
      in
      Normal [
        text ("Experimental " ^ config_name ^ " usage. ");
        text (String.capitalize_ascii config_name ^ "s are an active early stage ");
        text "feature proposal that may change. You may opt-in to using them ";
        text "anyway in Flow by putting "; code ("esproposal." ^ config_key ^ "=enable"); text " ";
        text "into the "; code "[options]"; text " section of your ";
        code ".flowconfig"; text ".";
      ]

    | EUnsafeGetSet _ ->
      Normal [
        text "Potentially unsafe get/set usage. Getters and setters with side ";
        text "effects are potentially unsafe and so disabled by default. You may ";
        text "opt-in to using them anyway by putting ";
        code "unsafe.enable_getters_and_setters"; text " into the ";
        code "[options]"; text " section of your "; code ".flowconfig"; text ".";
      ]

    | EExperimentalExportStarAs _ ->
      Normal [
        text "Experimental "; code "export * as"; text " usage. ";
        code "export * as"; text " is an active early stage feature propsal that ";
        text "may change. You may opt-in to using it anyway by putting ";
        code "esproposal.export_star_as=enable"; text " into the ";
        code "[options]"; text " section of your "; code ".flowconfig"; text ".";
      ]

    | EIndeterminateModuleType _ ->
      Normal [
        text "Unable to determine module type (CommonJS vs ES) if both an export ";
        text "statement and "; code "module.exports"; text " are used in the ";
        text "same module!";
      ]

    | EBadExportPosition _ ->
      Normal [
        text "Exports can only appear at the top level"
      ]

    | EBadExportContext (name, _) ->
      Normal [
        code name;
        text " may only be used as part of a legal top level export statement";
      ]

    | EUnexpectedTemporaryBaseType _ ->
      Normal [
        text "The type argument of a temporary base type must be a compatible literal type";
      ]

    | ESignatureVerification sve ->
      let open Signature_builder_deps.With_ALoc.Error in
      let msg = begin match sve with
        | ExpectedSort (sort, x, _) ->
          [code x; text (spf " is not a %s." (Signature_builder_kind.Sort.to_string sort))]
        | ExpectedAnnotation _ ->
          [text "Missing type annotation:"]
        | InvalidTypeParamUse _ ->
          [text "Invalid use of type parameter:"]
        | UnexpectedObjectKey _->
          [text "Expected simple key in object:"]
        | UnexpectedObjectSpread _ ->
          [text "Unexpected spread in object:"]
        | UnexpectedArraySpread _ ->
          [text "Unexpected spread in array:"]
        | UnexpectedArrayHole _ ->
          [text "Unexpected array hole:"]
        | EmptyArray _ ->
          [text "Cannot determine element type of empty array, try using a type cast."]
        | EmptyObject _ ->
          [text "Cannot determine types of initialized properties of empty object, try using a type cast."]
        | UnexpectedExpression (_, esort) ->
          [text (
              spf "Expected literal expression instead of %s, try using a type cast."
                (Flow_ast_utils.ExpressionSort.to_string esort)
          )]
        | SketchyToplevelDef _ ->
          [text "Unexpected toplevel definition that needs hoisting:"]
        | TODO (msg, _) ->
          [text (spf "TODO: %s is not supported yet, try using a type cast." msg)]
      end in
      Normal ((text "Could not build a typed interface for this module. ")::msg)

    | EUnreachable _ ->
      Normal [text "Unreachable code."]

    | EInvalidObjectKit { tool=_; reason; reason_op=_; use_op } ->
      UseOp (aloc_of_reason reason, [ref reason; text " is not an object"], use_op)

    | EInvalidTypeof (_, typename) ->
      Normal [
        text "Cannot compare the result of "; code "typeof"; text " to string ";
        text "literal "; code typename; text " because it is not a valid ";
        code "typeof"; text " return value.";
      ]

    | EArithmeticOperand reason ->
      Normal [
        text "Cannot perform arithmetic operation because "; ref reason; text " ";
        text "is not a number.";
      ]

    | EBinaryInLHS reason ->
      (* TODO: or symbol *)
      Normal [
        text "Cannot use "; code "in"; text " because on the left-hand side, ";
        ref reason; text " must be a string or number.";
      ]

    | EBinaryInRHS reason ->
      Normal [
        text "Cannot use "; code "in"; text " because on the right-hand side, ";
        ref reason; text " must be an object or array.";
      ]

    | EForInRHS reason ->
      Normal [
        text "Cannot iterate using a "; code "for...in"; text " statement ";
        text "because "; ref reason; text " is not an object, null, or undefined.";
      ]

    | EObjectComputedPropertyAccess (_, reason_prop) ->
      Normal
        [text "Cannot access computed property using "; ref reason_prop; text "."]

    | EObjectComputedPropertyAssign (_, reason_prop) ->
      Normal
        [text "Cannot assign computed property using "; ref reason_prop; text "."]

    | EInvalidLHSInAssignment _ ->
      Normal
        [text "Invalid left-hand side in assignment expression."]

    | EIncompatibleWithUseOp (l_reason, u_reason, use_op) ->
      Incompatible (l_reason, u_reason, use_op)

    | EUnsupportedImplements reason ->
      Normal [text "Cannot implement "; desc reason; text " because it is not an interface."]

    | EReactKit (reasons, tool, use_op) ->
      let open React in
      let (_, reason) = reasons in
      let is_not_prop_type = "is not a React propType" in
      let msg = match tool with
      | GetProps _
      | GetConfig _
      | GetRef _
      | CreateElement0 _
      | CreateElement _
        -> "is not a React component"
      | GetConfigType _
        -> "cannot calculate config"
      | SimplifyPropType (tool, _) ->
        SimplifyPropType.(match tool with
        | ArrayOf -> is_not_prop_type
        | InstanceOf -> "is not a class"
        | ObjectOf -> is_not_prop_type
        | OneOf ResolveArray -> "is not an array"
        | OneOf (ResolveElem _) -> "is not a literal"
        | OneOfType ResolveArray -> "is not an array"
        | OneOfType (ResolveElem _) -> is_not_prop_type
        | Shape ResolveObject -> "is not an object"
        | Shape (ResolveDict _) -> is_not_prop_type
        | Shape (ResolveProp _) -> is_not_prop_type
        )
      | CreateClass (tool, _, _) ->
        CreateClass.(match tool with
        | Spec _ -> "is not an exact object"
        | Mixins _ -> "is not a tuple"
        | Statics _ -> "is not an object"
        | PropTypes (_, ResolveObject) -> "is not an object"
        | PropTypes (_, ResolveDict _) -> is_not_prop_type
        | PropTypes (_, ResolveProp _) -> is_not_prop_type
        | DefaultProps _ -> "is not an object"
        | InitialState _ -> "is not an object or null"
        )
      in
      UseOp (aloc_of_reason reason, [ref reason; text (" " ^ msg)], use_op)

    | EReactElementFunArity (_, fn, n) ->
      Normal [
        text "Cannot call "; code ("React." ^ fn); text " ";
        text (spf "without at least %d argument%s." n (if n == 1 then "" else "s"));
      ]

    | EFunctionCallExtraArg (unused_reason, def_reason, param_count, use_op) ->
      let msg = match param_count with
      | 0 -> "no arguments are expected by"
      | 1 -> "no more than 1 argument is expected by"
      | n -> spf "no more than %d arguments are expected by" n
      in
      UseOp (aloc_of_reason unused_reason, [text msg; text " "; ref def_reason], use_op)

    | EUnsupportedSetProto _ ->
      Normal
        [text "Mutating this prototype is unsupported."]

    | EDuplicateModuleProvider {module_name; provider; _} ->
      let loc = Loc.(
        let pos = { line = 1; column = 0; } in
        { source = Some provider; start = pos; _end = pos }
      ) |> ALoc.of_loc in
      Normal [
        text "Duplicate module provider for "; code module_name; text ". Change ";
        text "either this module provider or the ";
        ref (mk_reason (RCustom "current module provider") loc);
        text ".";
      ]

    | EParseError (_, parse_error) ->
      Normal
        (Friendly.message_of_string (Parse_error.PP.error parse_error))

    | EDocblockError (_, err) ->
      let msg = match err with
      | MultipleFlowAttributes -> [
          text "Unexpected "; code "@flow"; text " declaration. Only one per ";
          text "file is allowed.";
        ]
      | MultipleProvidesModuleAttributes -> [
          text "Unexpected "; code "@providesModule"; text " declaration. ";
          text "Only one per file is allowed.";
        ]
      | MultipleJSXAttributes -> [
          text "Unexpected "; code "@jsx"; text " declaration. Only one per ";
          text "file is allowed.";
        ]
      | InvalidJSXAttribute first_error -> [
          text "Invalid "; code "@jsx"; text " declaration. Should have the form ";
          code "@jsx LeftHandSideExpression"; text " with no spaces.";
        ] @
        match first_error with
        | None -> []
        | Some first_error -> [text (spf " Parse error: %s." first_error)]
      in
      Normal msg

    | EUntypedTypeImport (_, module_name) ->
      Normal [
        text "Importing a type from an untyped module makes it "; code "any"; text " ";
        text "and is not safe! Did you mean to add "; code "// @flow"; text " to ";
        text "the top of "; code module_name; text "?";
      ]

    | EUntypedImport (_, module_name) ->
      Normal [
        text "Importing from an untyped module makes it "; code "any"; text " ";
        text "and is not safe! Did you mean to add "; code "// @flow"; text " ";
        text "to the top of "; code module_name; text "?";
      ]

    | ENonstrictImport _ ->
      Normal [
        text "Dependencies of a "; code "@flow strict"; text " module must ";
        text "also be "; code "@flow strict"; text "!"
      ]

    | EUnclearType _ ->
      Normal [
        text "Unclear type. Using "; code "any"; text ", ";
        code "Object"; text ", or "; code "Function";
        text " types is not safe!"
      ]

    | EDeprecatedType _ ->
      Normal [
        text "Deprecated type. Using "; code "*"; text " types is not recommended!"
      ]

    | EDeprecatedUtility (_, name) ->
      Normal [
        text "Deprecated utility. Using "; code name; text " types is not recommended!"
      ]

    | EDynamicExport (reason, reason_exp) ->
      Normal
        [text "Dynamic "; ref reason; text " unsafely appears in exported ";
        ref reason_exp; text ". This can cause importing modules to lose type coverage!"]

    | EUnsafeGettersSetters _ ->
      Normal
        [text "Getters and setters can have side effects and are unsafe."]

    | EDeprecatedCallSyntax _ ->
      Normal
        [text "Deprecated $call syntax. Use callable property syntax instead."]

    | EUnusedSuppression _ ->
      Normal
        [text "Unused suppression comment."]

    | ELintSetting (_, kind) ->
      let msg = match kind with
      | LintSettings.Redundant_argument -> [
          text "Redundant argument. This argument doesn't change any lint settings."
        ]
      | LintSettings.Overwritten_argument -> [
          text "Redundant argument. The values set by this argument are ";
          text "overwritten later in this comment.";
        ]
      | LintSettings.Naked_comment -> [
          text "Malformed lint rule. At least one argument is required."
        ]
      | LintSettings.Nonexistent_rule -> [
          text "Nonexistent/misspelled lint rule. Perhaps you have a ";
          text "missing/extra "; code ","; text "?";
        ]
      | LintSettings.Invalid_setting -> [
          text "Invalid setting. Valid settings are error, warn, and off."
        ]
      | LintSettings.Malformed_argument -> [
          text "Malformed lint rule. Properly formed rules contain a single ";
          code ":"; text " character. Perhaps you have a missing/extra ";
          code ","; text "?";
        ]
      in
      Normal msg

    | ESketchyNullLint { kind=sketchy_kind; loc=_; falsy_loc; null_loc } ->
      let type_str, value_str = match sketchy_kind with
      | Lints.SketchyNullBool -> "boolean", "false"
      | Lints.SketchyNullNumber -> "number", "0"
      | Lints.SketchyNullString -> "string", "an empty string"
      | Lints.SketchyNullMixed -> "mixed", "false"
      in
      Normal [
        text "Sketchy null check on "; ref (mk_reason (RCustom type_str) falsy_loc); text " ";
        text "which is potentially "; text value_str; text ". Perhaps you meant to ";
        text "check for "; ref (mk_reason RNullOrVoid null_loc); text "?";
      ]

    | ESketchyNumberLint (_, reason) ->
      Normal [
        text "Avoid using "; code "&&"; text " to check the value of "; ref reason; text ". ";
        text "Consider handling falsy values (0 and NaN) by using a conditional to choose an ";
        text "explicit default instead.";
      ]

    | EInvalidPrototype reason ->
      Normal
        [text "Cannot use "; ref reason; text " as a prototype. Expected an object or null."]

    | EExperimentalOptionalChaining _ ->
      Normal [
        text "Experimental optional chaining ("; code "?."; text ") usage. ";
        text "Optional chaining is an active early-stage feature proposal that ";
        text "may change. You may opt in to using it anyway by putting ";
        code "esproposal.optional_chaining=enable"; text " into the ";
        code "[options]"; text " section of your "; code ".flowconfig"; text ".";
      ]

    | EOptionalChainingMethods _ ->
      Normal [
        text "Flow does not yet support method or property calls in optional chains."
      ]

    | EUnnecessaryOptionalChain (_, lhs_reason)  ->
     Normal [
        text "This use of optional chaining ("; code "?."; text ") is unnecessary because ";
        ref lhs_reason; text " cannot be nullish or because an earlier "; code "?.";
        text " will short-circuit the nullish case.";
      ]

    | EUnnecessaryInvariant (_, reason)  ->
      Normal [
        text "This use of `invariant` is unnecessary because "; ref reason;
        text " is always truthy."
      ]

    | EInexactSpread (reason, reason_op) ->
      Normal [
        text "Cannot determine the type of "; ref reason_op; text " because ";
        text "it contains a spread of inexact "; ref reason; text ". ";
        text "Being inexact, "; ref reason;
        text " might be missing the types of some properties that are being copied. ";
        text "Perhaps you could make it exact?"
      ]
)

let is_lint_error = function
  | EUntypedTypeImport _
  | EUntypedImport _
  | ENonstrictImport _
  | EUnclearType _
  | EDeprecatedType _
  | EDeprecatedUtility _
  | EDynamicExport _
  | EUnsafeGettersSetters _
  | ESketchyNullLint _
  | ESketchyNumberLint _
  | EInexactSpread _
  | EUnnecessaryOptionalChain _
  | EUnnecessaryInvariant _
      -> true
  | _ -> false