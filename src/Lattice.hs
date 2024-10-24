-- DO NOT EDIT THIS FILE.
-- Unless you want to optimize it for fun



module Lattice
  ( Lattice (..)
  , Env
  , get
  , convertToEnv
  , getHasse
  , getLattice
  , isDAG
  , reflexiveTransitive
  ) where

import qualified Data.Map as Map
import Prelude
import Nano
import Data.List (nub, find, intersect)

-- This is probably the least optimized piece of code you will ever use :) 
-- If you want to optimize these functions for recreational purposes, go for it.


-- Define type synonyms
type Join a = a -> a -> a
type Meet a = a -> a -> a
type LTE a = a -> a -> Bool


-- Define the Lattice data type
data Lattice a = Lattice
    { join    :: Join a
    , meet    :: Meet a
    , lte     :: LTE a
    , smallest :: a
    }

-- Environment type for variable mapping
type Env a = Map.Map a String


-- Get the value from the environment
get :: Ord a => Env a -> a -> String
get env s = env Map.! s

-- Convert a list of tuples to an Env
convertToEnv :: (Ord k) => [(k, String)] -> Env k
convertToEnv = Map.fromList

getHasse :: Nano String -> [(String, String)]
getHasse n =
  let Just hasseFunc = find (\x -> fname x == "hasse") n
  in fhasse hasseFunc


-- Return a Lattice for the given Hasse diagram
getLattice :: [(String, String)] -> Lattice String
getLattice edgelist =
  if not (isDAG edgelist)
    then error "This graph has cycles"
    else let rt = reflexiveTransitive edgelist
             rt' = reflexiveTransitive [(b, a) | (a, b) <- rt]
             latticeJoin = getJoin rt
             latticeMeet = getJoin rt'
             latticeLTE = getLTE rt
             latticeSmallest = getSmallest rt
       in Lattice latticeJoin latticeMeet latticeLTE latticeSmallest

-- Get the join of two elements
getJoin :: [(String, String)] -> Join String
getJoin rt a b =
  let greaterA = [y | (x, y) <- rt, x == a]
      greaterB = [y | (x, y) <- rt, x == b]
      greaterAB = intersect greaterA greaterB
      lubab = [y | y <- greaterAB, all (\ab -> (y, ab) `elem` rt) greaterAB]
  in head lubab  -- Will crash if lubab is empty

-- Check if one element is less than or equal to another
getLTE :: [(String, String)] -> LTE String
getLTE rt a b = (a, b) `elem` rt

-- Get the smallest element
getSmallest :: [(String, String)] -> String
getSmallest rt =
  let (as, bs) = unzip rt
      elements = nub (as ++ bs)
      lubab = [y | y <- elements, all (\ab -> (y, ab) `elem` rt) elements]
  in head lubab  -- Will crash if lubab is empty

-- Check if the graph is a DAG
isDAG :: Eq a => [(a, a)] -> Bool
isDAG edgeList =
  let tc = transitiveClosure edgeList
  in not $ any (uncurry (==)) tc

-- Calculate the reflexive transitive closure
reflexiveTransitive :: Eq a => [(a, a)] -> [(a, a)]
reflexiveTransitive el = let r = reflexiveClosure el in transitiveClosure r

-- Calculate the transitive closure
transitiveClosure :: Eq a => [(a, a)] -> [(a, a)]
transitiveClosure el =
  let elnew = nub (el ++ [(a, d) | (a, b) <- el, (c, d) <- el, b == c])
  in if el == elnew then elnew else transitiveClosure elnew


-- Calculate the reflexive closure
reflexiveClosure :: Eq a => [(a, a)] -> [(a, a)]
reflexiveClosure el =
  let (as, bs) = unzip el
  in nub $ el ++ [(x, x) | x <- nub (as ++ bs)]

