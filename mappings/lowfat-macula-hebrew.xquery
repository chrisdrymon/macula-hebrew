(:
    Convert GBI trees to Lowfat format.

	NOTE: this should rarely be used now that the lowfat trees
	are being independently, but I am keeping it in the repo
	for documentation purposes and also for quality assurance,
	as a way of testing the lowfat trees against GBI as we
	move forward.

	If it is used, remember to do the following steps:

	- Search for duplicate IDs, removing the second GBI interpretation when there are duplicate subtrees.
	- Search for the single instance where a word is not in any word group, but directly in a sentence.
	- Do a diff to make sure things make sense.

:)


declare variable $retain-singletons := false();

declare function local:USFMBook($nodeId)
{
if(string-length($nodeId) < 1)
then "error5"
else
    switch (xs:integer(substring($nodeId, 1, 2)))
        case 01 return "GEN"
        case 02 return "EXO"
        case 03 return "LEV"
        case 04 return "NUM"
        case 05 return "DEU"
        case 06 return "JOS"
        case 07 return "JDG"
        case 08 return "RUT"
        case 09 return "1SA"
        case 10 return "2SA"
        case 11 return "1KI"
        case 12 return "2KI"
        case 13 return "1CH"
        case 14 return "2CH"
        case 15 return "EZR"
        case 16 return "NEH"
        case 17 return "EST"
        case 18 return "JOB"
        case 19 return "PSA"
        case 20 return "PRO"
        case 21 return "ECC"
        case 22 return "SNG"
        case 23 return "ISA"
        case 24 return "JER"
        case 25 return "LAM"
        case 26 return "EZK"
        case 27 return "DAN"
        case 28 return "HOS"
        case 29 return "JOL"
        case 30 return "AMO"
        case 31 return "OBA"
        case 32 return "JON"
        case 33 return "MIC"
        case 34 return "NAM"
        case 35 return "HAB"
        case 36 return "ZEP"
        case 37 return "HAG"
        case 38 return "ZEC"
        case 39 return "MAL"
        case 40 return "MAT"
        case 41 return "MRK"
        case 42 return "LUK"
        case 43 return "JHN"
        case 44 return "ACT"
        case 45 return "ROM"
        case 46 return "1CO"
        case 47 return "2CO"
        case 48 return "GAL"
        case 49 return "EPH"
        case 50 return "PHP"
        case 51 return "COL"
        case 52 return "1TH"
        case 53 return "2TH"
        case 54 return "1TI"
        case 55 return "2TI"
        case 56 return "TIT"
        case 57 return "PHM"
        case 58 return "HEB"
        case 59 return "JAS"
        case 60 return "1PE"
        case 61 return "2PE"
        case 62 return "1JN"
        case 63 return "2JN"
        case 64 return "3JN"
        case 65 return "JUD"
        case 66 return "REV"
        default return "###"
};

declare function local:verbal-noun-type($node)
(:  This realy doesn't work yet. Not even close. :)
{
    switch ($node/parent::Node/@Cat)
        case 'adjp'
            return
                attribute type {'adjectival'}
        case 'advp'
            return
                attribute type {'adverbial'}
        case 'np'
            return
                attribute type {'nominal'}
        default return
            attribute type {'?'}
};

declare function local:head($node)
{
    if ($node)
    then
        let $preceding := count($node/preceding-sibling::Node)
        let $following := count($node/following-sibling::Node)
        return
            if ($preceding + $following > 0)
            then
                if ($preceding = $node/parent::*/@Head and $node/parent::*/@Cat != 'conj')
                then
                    attribute head {true()}
                else
                    ()
            else
                local:head($node/parent::*)
    else
        ()

};

declare function local:attributes($node)
{
    $node/@ID ! attribute ID {lower-case(.)},
    $node/@Cat ! attribute class {lower-case(.)},
    $node/@Head ! attribute Head {if (. = '0') then true() else false()},
    $node/@nodeId ! attribute nodeId {lower-case(.)},
    $node/@Rule ! attribute Rule {lower-case(.)},
    $node/@n ! attribute n {lower-case(.)},
    $node/@morphId ! attribute morphId {lower-case(.)},
    $node/@Unicode ! attribute Unicode {lower-case(.)},
    $node/@morph ! attribute morph {.},
    $node/@lang ! attribute lang {.},
    $node/@lemma ! attribute lemma {.},
    $node/@pos ! attribute pos {lower-case(.)},
    $node/@gender ! attribute gender {lower-case(.)},
    $node/@number ! attribute number {lower-case(.)},
    $node/@state ! attribute state {lower-case(.)},
    $node/@stem ! attribute stem {lower-case(.)},
    $node/@person ! attribute person {lower-case(.)},
    $node/@after
};

(: TODO: the USFM id does not need to be computed from the Nodes trees, since USFM ids are now included on verses and words :)
declare function local:USFMId($nodeId)
{
if(string-length($nodeId) < 1) 
then "error6NoIDFoundInNode"
else
    concat(local:USFMBook($nodeId),
    " ",
    xs:integer(substring($nodeId, 3, 3)),
    ":",
    xs:integer(substring($nodeId, 6, 3)),
    "!",
    xs:integer(substring($nodeId, 9, 3))
    )
};


declare function local:USFMVerseId($nodeId)
{
if(string-length($nodeId) < 1) 
then "error7"
else
    concat(local:USFMBook($nodeId),
    ".",
    xs:integer(substring($nodeId, 3, 3)),
    ".",
    xs:integer(substring($nodeId, 6, 3))
    )
};

declare function local:oneword($node as element(Node))
(: If the Node governs a single word, return that word. :)
{
    if (count($node/Node) > 1)
    then
        ()
    else
        if ($node/Node)
        then
            local:oneword($node/Node)
        else
            if ($node/c)
            then
                ()
            else $node
};

declare function local:sub-CL-adjunct($node)
{
    
    
    
};

declare function local:sub-CL-adjunct-parent($node)
{
    
    let $first := $node/Node[1]
    let $second := $node/Node[2]
    return
        if ($first[@Rule = 'sub-CL']) then
            <wg>
                {
                    local:attributes($second),
                    <!-- one -->,
                    $first ! local:node(.),
                    $second/Node ! local:node(.)
                }
            </wg>
        else
            if ($second[@Rule = 'sub-CL']) then
                <wg>
                    {
                        local:attributes($first),
                        <!-- two -->,
                        $first/Node ! local:node(.),
                        $second ! local:node(.)
                    }
                </wg>
            else
                <error2>{"Something went wrong.", "First:", $first, "Second:", $second}</error2>
};

declare function local:is-worth-preserving($clause)
{
    local:node-type($clause/parent::*) = 'role'
    or $clause/@Rule = 'sub-CL'
    or not($clause/@Rule = ('ClCl', 'ClCl2'))
};

declare function local:clause($node)
(:  This is probably too simple as written - need to do restructuring of clauses based on @rule attributes  :)
{
    if (local:is-worth-preserving($node))
    then
        <wg>
            {
                local:attributes($node),
                $node/Node ! local:node(.)
            }
        </wg>
    else
        $node/Node ! local:node(.)
};

declare function local:rclause($node)
{
    if (local:is-worth-preserving($node))
    then
        <wg
            clauseType='relative'>
            {
                local:attributes($node),
                $node/Node ! local:node(.)
            }
        </wg>
    else
        $node/Node ! local:node(.)
};

declare function local:compound($nodeWithCChild)
{
(: If a node has a <c> child, it is the only child :)
    <wg
        class='compound'>
        {
            local:attributes($nodeWithCChild),
            $nodeWithCChild//m ! local:m(.)
        }
    </wg>
};

declare function local:phrase($node)
{
    if (local:oneword($node))
    then
        (local:m(local:oneword($node)/m)) (: PICKING UP: running into problems with oneword - probably when it hits a <c> element :)
    else
        <wg>
            {
                local:attributes($node),
                $node/Node ! local:node(.)
            }
        </wg>
};

declare function local:role($node)
(:
  A role node can have more than one child in some
  corner cases in the GBI trees, e.g. Gal 4:18, where
  an ADV node contains ADV conj ADV.  I imagine this
  occurs only for conjunctions, but I am not sure.
:)
{
    let $role := attribute role {lower-case($node/@Cat)}
    return
        if (local:oneword($node))
        then
            (local:m-with-role(local:oneword($node)/m, $role))
        else
            if (count($node/Node) > 1)
            then
                <wg>
                    {
                        $role,
                        $node/Node ! local:node(.)
                    }
                </wg>
            else
                <wg>
                    {
                        $role,
                        local:attributes($node/Node),
                        $node/Node/Node ! local:node(.)
                    }
                </wg>
};

declare function local:m($m as element(m))
{
    local:m-with-role($m, ()) 
};

declare function local:m-with-role($m as element(), $role)
(: $role can contain a role attribute or a null sequence :)
{
    if(name($m) = 'Node')
    then
        element error10 {$role, $m, 'error location id:', data($m/@n)}
    else if(name($m) = 'c')
    then
        element error12 {$role, $m, 'error location id:', data($m/@n)}    
    else if ($m/*)
    then
        (element error1 {$role, $m})
    else
        <w USFMId='{local:USFMId($m/ancestor::Node[1]/@nodeId)}'>
            {
                (: get the @Cat etc. from the ancestor::Node[1] :)
                $role,
                $m/ancestor::Node[1]/@morphId,
                $m/ancestor::Node[1]/@Cat,
                $m/ancestor::Node[1]/@Unicode,
                $m/ancestor::Node[1]/@nodeId,
                local:attributes($m),
                string($m/text())
                
            }
        </w>
};

declare function local:node-type($node as element(Node))
{
    if ($node/c)
    then 
        "compound"
    else if ($node/m and not($node/c))
    then
        "word"
    else
        switch ($node/@Cat)
            case "CL"
                return
                    "clause"
            case "S"
            case "V"
            case "O"
            case "O2"
            case "P"
            case "PP"
            case "ADV"
                return
                    "role"
            case "relp"
                return
                    "rclause"
            case "pp"
            case "np"
            case "vp"
            case "omp"
            case "adjp"
            case "nump"
            case "cjp"
            case "advp"
            case "vp"
            case "ijp"
                return
                    "phrase"
            case "prep"
            case "ptcl"
            case "noun"
            case "verb"
            case "om"
            case "art"
            case "cj"
            case "adj"
            case "num"
            case "rel"
            case "pron"
            case "adv"
            case "ij"
            case "x"
                return
                    "nonPhrase"
            default
                return
                    "#error4_Unknown_Category"
};

declare function local:node($node as element(Node))
{
    switch (local:node-type($node))
        case "compound"
            return
                local:compound($node/c)
        case "word"
            return
                local:m($node/m)
        case "phrase"
            return
                local:phrase($node)
        case "rclause"
            return
                local:rclause($node)
        case "role"
            return
                local:role($node)
        case "clause"
            return
                local:clause($node)
        case "nonPhrase"
            return
                local:oneword($node)
        default
        return <error3>{$node}</error3>
};

declare function local:straight-text($node)
{
    for $n at $i in $node//Node[local:node-type(.) = 'word']
        order by $n/@morphId
    return
        string($n/m/text())
};

declare function local:sentence($node)
{
    <sentence>
        {
            <p>
                {
                    for $verse in distinct-values($node//Node/@morphId ! local:USFMVerseId(.))
                    return
                        (
                        <milestone
                            unit="verse">
                            {attribute id {$verse}, $verse}
                        </milestone>
                        ,
                        " "
                        )
                }
                {local:straight-text($node)}
            </p>,
            
            if (count($node/Node) > 1 or not($node/Node/@Cat = 'CL'))
            (: If the current node has multiple node children, OR it does not have a clause child :)
            then
                <wg
                    role="cl">{$node/Node ! local:node(.)}</wg>
            else
                local:node($node/Node)
            
        }
    </sentence>
};

processing-instruction xml-stylesheet {'href="hebrew-treedown.css"'},
processing-instruction xml-stylesheet {'href="hebrew-boxwood.css"'},
<chapter id="{/Sentences/Sentence[1]/Trees[1]/Tree[1]/Node[1]/local:USFMBook(@nodeId)}">
    {
        (:
            If a sentence has multiple interpretations, Sentence/Trees may contain
            multiple Tree nodes.  We want to specify which interpretation to prefer.
        :)
        let $interpretationToPrefer := 1
        for $sentence in //Tree[$interpretationToPrefer]/Node
        return
            local:sentence($sentence)
    }
</chapter>