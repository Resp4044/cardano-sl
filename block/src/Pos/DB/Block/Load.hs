-- | Loading sequence of blunds.

module Pos.DB.Block.Load
       (
       -- * Load data
         loadBlundsWhile
       , loadBlundsByDepth
       , loadBlocksWhile
       , loadHeadersWhile
       , loadHeadersByDepth

       -- * Load data from tip
       , loadBlundsFromTipWhile
       , loadBlundsFromTipByDepth
       ) where

import           Universum

import           Control.Lens (_Wrapped)
import           Formatting (sformat, (%))

import           Pos.Binary.Core ()
import           Pos.Block.Types (Blund)
<<<<<<< HEAD
import           Pos.Core (BlockCount, HasDifficulty (difficultyL),
                           HasPrevBlock (prevBlockL), HeaderHash, HasGenesisHash)
=======
import           Pos.Core (BlockCount, HasConfiguration, HasDifficulty (difficultyL),
                           HasPrevBlock (prevBlockL), HeaderHash)
>>>>>>> CHW-82-84, orphan branch
import           Pos.Core.Block (Block, BlockHeader)
import           Pos.Core.Configuration (genesisHash)
import           Pos.Crypto (shortHashF)
import           Pos.DB.Block (getBlund)
import           Pos.DB.BlockIndex (getHeader)
import           Pos.DB.Class (MonadBlockDBRead, MonadDBRead, getBlock)
import           Pos.DB.Error (DBError (..))
import           Pos.DB.GState.Common (getTip)
import           Pos.Util.Chrono (NewestFirst (..))
import           Pos.Util.Util (maybeThrow)

type LoadHeadersMode m =
<<<<<<< HEAD
    ( MonadDBRead m
=======
    ( HasConfiguration
    , MonadDBRead m
>>>>>>> CHW-82-84, orphan branch
    )

----------------------------------------------------------------------------
-- Load
----------------------------------------------------------------------------

loadDataWhile
    :: forall m a .
<<<<<<< HEAD
       (Monad m, HasPrevBlock a, HasGenesisHash)
=======
       (Monad m, HasPrevBlock a, HasConfiguration)
>>>>>>> CHW-82-84, orphan branch
    => (HeaderHash -> m a)
    -> (a -> Bool)
    -> HeaderHash
    -> m (NewestFirst [] a)
loadDataWhile getter predicate start = NewestFirst <$> doIt [] start
  where
    doIt :: [a] -> HeaderHash -> m [a]
    doIt !acc h
        | h == genesisHash = pure (reverse acc)
        | otherwise = do
            d <- getter h
            let prev = d ^. prevBlockL
            if predicate d
                then doIt (d : acc) prev
                else pure (reverse acc)

-- For depth 'd' load blocks that have depth < 'd'. Given header
-- (newest one) is assumed to have depth 0.
loadDataByDepth
    :: forall m a .
<<<<<<< HEAD
       (Monad m, HasPrevBlock a, HasDifficulty a, HasGenesisHash)
=======
       (Monad m, HasPrevBlock a, HasDifficulty a, HasConfiguration)
>>>>>>> CHW-82-84, orphan branch
    => (HeaderHash -> m a)
    -> (a -> Bool)
    -> BlockCount
    -> HeaderHash
    -> m (NewestFirst [] a)
loadDataByDepth _ _ 0 _ = pure (NewestFirst [])
loadDataByDepth getter extraPredicate depth h = do
    -- First of all, we load data corresponding to h.
    top <- getter h
    let topDifficulty = top ^. difficultyL
    -- If top difficulty is 0, we can load all data starting from it.
    -- Then we calculate difficulty of data at which we should stop.
    -- Difficulty of the oldest data to return is 'topDifficulty - depth + 1'
    -- So we are loading all blocks which have difficulty ≥ targetDifficulty.
    let targetDelta = fromIntegral depth - 1
        targetDifficulty
            | topDifficulty <= targetDelta = 0
            | otherwise = topDifficulty - targetDelta
    -- Then we load blocks starting with previous block of already
    -- loaded block.  We load them until we find block with target
    -- difficulty. And then we drop last (oldest) block.
    let prev = top ^. prevBlockL
    over _Wrapped (top :) <$>
        loadDataWhile
        getter
        (\a -> a ^. difficultyL >= targetDifficulty && extraPredicate a)
        prev

-- | Load blunds starting from block with header hash equal to given hash
-- and while @predicate@ is true.
loadBlundsWhile
<<<<<<< HEAD
    :: (MonadDBRead m, HasGenesisHash)
=======
    :: MonadDBRead m
>>>>>>> CHW-82-84, orphan branch
    => (Block -> Bool) -> HeaderHash -> m (NewestFirst [] Blund)
loadBlundsWhile predicate = loadDataWhile getBlundThrow (predicate . fst)

-- | Load blunds which have depth less than given (depth = number of
-- blocks that will be returned).
loadBlundsByDepth
<<<<<<< HEAD
    :: (MonadDBRead m, HasGenesisHash)
=======
    :: MonadDBRead m
>>>>>>> CHW-82-84, orphan branch
    => BlockCount -> HeaderHash -> m (NewestFirst [] Blund)
loadBlundsByDepth = loadDataByDepth getBlundThrow (const True)

-- | Load blocks starting from block with header hash equal to given hash
-- and while @predicate@ is true.
loadBlocksWhile
<<<<<<< HEAD
    :: (MonadBlockDBRead m, HasGenesisHash)
=======
    :: MonadBlockDBRead m
>>>>>>> CHW-82-84, orphan branch
    => (Block -> Bool) -> HeaderHash -> m (NewestFirst [] Block)
loadBlocksWhile = loadDataWhile getBlockThrow

-- | Load headers starting from block with header hash equal to given hash
-- and while @predicate@ is true.
loadHeadersWhile
<<<<<<< HEAD
    :: ( LoadHeadersMode m, HasGenesisHash )
=======
    :: LoadHeadersMode m
>>>>>>> CHW-82-84, orphan branch
    => (BlockHeader -> Bool)
    -> HeaderHash
    -> m (NewestFirst [] BlockHeader)
loadHeadersWhile = loadDataWhile getHeaderThrow

-- | Load headers which have depth less than given.
loadHeadersByDepth
<<<<<<< HEAD
    :: ( LoadHeadersMode m, HasGenesisHash )
=======
    :: LoadHeadersMode m
>>>>>>> CHW-82-84, orphan branch
    => BlockCount -> HeaderHash -> m (NewestFirst [] BlockHeader)
loadHeadersByDepth = loadDataByDepth getHeaderThrow (const True)

----------------------------------------------------------------------------
-- Load from tip
----------------------------------------------------------------------------

-- | Load blunds from BlockDB starting from tip and while the @condition@ is
-- true.
loadBlundsFromTipWhile
<<<<<<< HEAD
    :: (MonadDBRead m, HasGenesisHash)
=======
    :: MonadDBRead m
>>>>>>> CHW-82-84, orphan branch
    => (Block -> Bool) -> m (NewestFirst [] Blund)
loadBlundsFromTipWhile condition = getTip >>= loadBlundsWhile condition

-- | Load blunds from BlockDB starting from tip which have depth less than
-- given.
loadBlundsFromTipByDepth
<<<<<<< HEAD
    :: (MonadDBRead m, HasGenesisHash)
=======
    :: MonadDBRead m
>>>>>>> CHW-82-84, orphan branch
    => BlockCount -> m (NewestFirst [] Blund)
loadBlundsFromTipByDepth d = getTip >>= loadBlundsByDepth d

----------------------------------------------------------------------------
-- Private functions
----------------------------------------------------------------------------

getBlockThrow
    :: MonadBlockDBRead m
    => HeaderHash -> m Block
getBlockThrow hash =
    maybeThrow (DBMalformed $ sformat errFmt hash) =<< getBlock hash
  where
    errFmt = "getBlockThrow: no block with HeaderHash: "%shortHashF

getHeaderThrow
    :: LoadHeadersMode m
    => HeaderHash -> m BlockHeader
getHeaderThrow hash =
    maybeThrow (DBMalformed $ sformat errFmt hash) =<< getHeader hash
  where
    errFmt = "getBlockThrow: no block header with hash: "%shortHashF

getBlundThrow
    :: MonadDBRead m
    => HeaderHash -> m Blund
getBlundThrow hash =
    maybeThrow (DBMalformed $ sformat errFmt hash) =<< getBlund hash
  where
    errFmt = "getBlundThrow: no blund with HeaderHash: "%shortHashF
