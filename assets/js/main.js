// ComplexSQL - Main JavaScript

document.addEventListener('DOMContentLoaded', function() {
    initializeTabs();
    initializeAnimations();
    initializeCopyButtons();
    initializeInteractiveVisualizations();
});

// Database Tab Switching
function initializeTabs() {
    const tabContainers = document.querySelectorAll('.db-tabs-container');
    
    tabContainers.forEach(container => {
        const tabs = container.querySelectorAll('.db-tab');
        const contents = container.querySelectorAll('.db-content');
        
        tabs.forEach(tab => {
            tab.addEventListener('click', () => {
                const targetDb = tab.dataset.db;
                
                // Update active tab
                tabs.forEach(t => t.classList.remove('active'));
                tab.classList.add('active');
                
                // Show corresponding content
                contents.forEach(content => {
                    content.classList.remove('active');
                    if (content.dataset.db === targetDb) {
                        content.classList.add('active');
                    }
                });
            });
        });
    });
}

// Scroll Animations
function initializeAnimations() {
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('animate-fade-in');
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);
    
    document.querySelectorAll('.section-4wh, .visualization-3d, .sql-container').forEach(el => {
        observer.observe(el);
    });
}

// Copy SQL Code to Clipboard
function initializeCopyButtons() {
    document.querySelectorAll('.sql-container').forEach(container => {
        const header = container.querySelector('.sql-header');
        const code = container.querySelector('.sql-code');
        
        if (header && code) {
            const copyBtn = document.createElement('button');
            copyBtn.className = 'copy-btn';
            copyBtn.innerHTML = '📋 Copy';
            copyBtn.style.cssText = `
                background: rgba(255,255,255,0.1);
                border: 1px solid rgba(255,255,255,0.2);
                color: white;
                padding: 5px 12px;
                border-radius: 5px;
                cursor: pointer;
                font-size: 0.8rem;
                transition: all 0.3s ease;
            `;
            
            copyBtn.addEventListener('click', async () => {
                const text = code.textContent;
                try {
                    await navigator.clipboard.writeText(text);
                    copyBtn.innerHTML = '✓ Copied!';
                    setTimeout(() => {
                        copyBtn.innerHTML = '📋 Copy';
                    }, 2000);
                } catch (err) {
                    console.error('Failed to copy:', err);
                }
            });
            
            copyBtn.addEventListener('mouseenter', () => {
                copyBtn.style.background = 'rgba(255,255,255,0.2)';
            });
            
            copyBtn.addEventListener('mouseleave', () => {
                copyBtn.style.background = 'rgba(255,255,255,0.1)';
            });
            
            header.appendChild(copyBtn);
        }
    });
}

// Interactive Visualizations
function initializeInteractiveVisualizations() {
    // 3D Table Hover Effects
    document.querySelectorAll('.table-3d-wrapper').forEach(wrapper => {
        wrapper.addEventListener('mouseenter', () => {
            wrapper.style.animationPlayState = 'paused';
            wrapper.style.transform = 'translateY(-15px) rotateX(5deg) rotateY(0deg) scale(1.05)';
        });
        
        wrapper.addEventListener('mouseleave', () => {
            wrapper.style.animationPlayState = 'running';
            wrapper.style.transform = '';
        });
    });
    
    // Row Highlighting on Hover
    document.querySelectorAll('.table-visual tr').forEach(row => {
        row.addEventListener('mouseenter', () => {
            row.style.transition = 'all 0.3s ease';
        });
    });
    
    // Join Visualization Interactions
    initializeJoinVisualizations();
}

// Join Diagram Interactions
function initializeJoinVisualizations() {
    const joinContainers = document.querySelectorAll('.join-visual-container');
    
    joinContainers.forEach(container => {
        const leftCircle = container.querySelector('.join-circle.left');
        const rightCircle = container.querySelector('.join-circle.right');
        const intersection = container.querySelector('.join-intersection');
        
        if (leftCircle && rightCircle) {
            // Highlight matching rows on hover
            leftCircle.addEventListener('mouseenter', () => {
                highlightJoinRows(container, 'left');
            });
            
            rightCircle.addEventListener('mouseenter', () => {
                highlightJoinRows(container, 'right');
            });
            
            if (intersection) {
                intersection.addEventListener('mouseenter', () => {
                    highlightJoinRows(container, 'both');
                });
            }
        }
    });
}

function highlightJoinRows(container, side) {
    const leftTable = container.querySelector('.left-table');
    const rightTable = container.querySelector('.right-table');
    const resultTable = container.querySelector('.result-table');
    
    // Reset highlights
    container.querySelectorAll('tr').forEach(row => {
        row.classList.remove('highlight', 'highlight-blue', 'highlight-yellow');
    });
    
    // Apply highlights based on side
    if (side === 'left' || side === 'both') {
        leftTable?.querySelectorAll('tr.matched').forEach(row => {
            row.classList.add('highlight-blue');
        });
    }
    
    if (side === 'right' || side === 'both') {
        rightTable?.querySelectorAll('tr.matched').forEach(row => {
            row.classList.add('highlight-yellow');
        });
    }
    
    if (side === 'both') {
        resultTable?.querySelectorAll('tr').forEach(row => {
            row.classList.add('highlight');
        });
    }
}

// SQL Syntax Highlighting
function highlightSQL(code) {
    const keywords = ['SELECT', 'FROM', 'WHERE', 'JOIN', 'INNER', 'LEFT', 'RIGHT', 'FULL', 'OUTER', 
                      'ON', 'AND', 'OR', 'NOT', 'IN', 'BETWEEN', 'LIKE', 'IS', 'NULL', 'AS',
                      'ORDER', 'BY', 'ASC', 'DESC', 'GROUP', 'HAVING', 'LIMIT', 'OFFSET',
                      'INSERT', 'INTO', 'VALUES', 'UPDATE', 'SET', 'DELETE', 'CREATE', 'TABLE',
                      'ALTER', 'DROP', 'INDEX', 'VIEW', 'PROCEDURE', 'FUNCTION', 'TRIGGER',
                      'BEGIN', 'END', 'IF', 'ELSE', 'THEN', 'CASE', 'WHEN', 'ELSE', 'END',
                      'UNION', 'ALL', 'INTERSECT', 'EXCEPT', 'MINUS', 'EXISTS', 'DISTINCT',
                      'COUNT', 'SUM', 'AVG', 'MIN', 'MAX', 'OVER', 'PARTITION', 'ROW_NUMBER',
                      'RANK', 'DENSE_RANK', 'NTILE', 'LAG', 'LEAD', 'FIRST_VALUE', 'LAST_VALUE',
                      'WITH', 'RECURSIVE', 'CTE', 'COMMIT', 'ROLLBACK', 'SAVEPOINT', 'GRANT', 'REVOKE',
                      'PRIMARY', 'KEY', 'FOREIGN', 'REFERENCES', 'UNIQUE', 'CHECK', 'DEFAULT',
                      'CONSTRAINT', 'CASCADE', 'RESTRICT', 'TOP', 'FETCH', 'NEXT', 'ROWS', 'ONLY',
                      'CROSS', 'NATURAL', 'USING', 'COALESCE', 'NULLIF', 'CAST', 'CONVERT'];
    
    const functions = ['CONCAT', 'SUBSTRING', 'LENGTH', 'UPPER', 'LOWER', 'TRIM', 'LTRIM', 'RTRIM',
                       'REPLACE', 'CHARINDEX', 'PATINDEX', 'STUFF', 'REVERSE', 'LEFT', 'RIGHT',
                       'GETDATE', 'CURRENT_DATE', 'CURRENT_TIMESTAMP', 'DATEADD', 'DATEDIFF',
                       'YEAR', 'MONTH', 'DAY', 'HOUR', 'MINUTE', 'SECOND', 'DATEPART', 'DATENAME',
                       'ABS', 'CEILING', 'FLOOR', 'ROUND', 'POWER', 'SQRT', 'MOD', 'RAND',
                       'ISNULL', 'NVL', 'IFNULL', 'IIF', 'CHOOSE', 'GREATEST', 'LEAST'];
    
    let highlighted = code;
    
    // Highlight keywords
    keywords.forEach(keyword => {
        const regex = new RegExp(`\\b(${keyword})\\b`, 'gi');
        highlighted = highlighted.replace(regex, '<span class="keyword">$1</span>');
    });
    
    // Highlight functions
    functions.forEach(func => {
        const regex = new RegExp(`\\b(${func})\\s*\\(`, 'gi');
        highlighted = highlighted.replace(regex, '<span class="function">$1</span>(');
    });
    
    // Highlight strings
    highlighted = highlighted.replace(/'([^']*)'/g, '<span class="string">\'$1\'</span>');
    
    // Highlight numbers
    highlighted = highlighted.replace(/\b(\d+)\b/g, '<span class="number">$1</span>');
    
    // Highlight comments
    highlighted = highlighted.replace(/--(.*?)$/gm, '<span class="comment">--$1</span>');
    highlighted = highlighted.replace(/\/\*([\s\S]*?)\*\//g, '<span class="comment">/*$1*/</span>');
    
    return highlighted;
}

// Utility: Format SQL for display
function formatSQL(sql) {
    return sql
        .replace(/\s+/g, ' ')
        .replace(/\s*,\s*/g, ',\n    ')
        .replace(/\s+(FROM|WHERE|JOIN|INNER|LEFT|RIGHT|FULL|ON|AND|OR|ORDER|GROUP|HAVING|LIMIT)/gi, '\n$1')
        .trim();
}

// Export functions for use in HTML
window.ComplexSQL = {
    highlightSQL,
    formatSQL,
    highlightJoinRows
};
