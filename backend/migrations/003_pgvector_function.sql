-- ============================================================
-- SalamaRecover: pgvector RPC Function for RAG
-- Run this AFTER 001_initial_schema.sql
-- ============================================================

-- This function is called by rag_service.py via:
--   db.rpc("match_knowledge_base", { query_embedding, match_threshold, match_count })

CREATE OR REPLACE FUNCTION match_knowledge_base(
    query_embedding vector(768),
    match_threshold float,
    match_count int
)
RETURNS TABLE (
    id uuid,
    content text,
    source text,
    page int,
    metadata jsonb,
    similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        kb.id,
        kb.content,
        kb.source,
        kb.page,
        kb.metadata,
        (1 - (kb.embedding <=> query_embedding))::float AS similarity
    FROM knowledge_base kb
    WHERE 1 - (kb.embedding <=> query_embedding) > match_threshold
    ORDER BY kb.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;
